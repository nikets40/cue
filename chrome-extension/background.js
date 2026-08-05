// Owns the WebSocket to Cue Booth and forwards media metadata from any tab.
// Booth accepts this connection because it arrives over loopback with
// role "provider" — the extension has no way to read the pairing token.

const BOOTH_URL = "ws://127.0.0.1:41952";
const RECONNECT_MS = 5000;
const MAX_ARTWORK_BYTES = 600 * 1024;

let socket = null;
let connecting = false;
const artworkCache = new Map(); // artwork src -> { base64, mimeType }
let lastSentKey = "";
/** Tab that last reported itself as playing — the one commands act on. */
let playingTabId = null;
/** Latest report from every tab holding media, so paused ones stay listable. */
const tabStates = new Map();

const SERVICES = [
  ["music.youtube.com", "ytmusic"],
  ["youtube.com", "youtube"],
  ["netflix.com", "netflix"],
  ["primevideo.com", "prime"],
  ["amazon.", "prime"],
  ["hotstar.com", "hotstar"],
  ["jiohotstar.com", "hotstar"],
  ["open.spotify.com", "spotify"],
];

function serviceFor(href) {
  let host = "";
  try {
    host = new URL(href).hostname.toLowerCase();
  } catch {
    return null;
  }
  for (const [fragment, service] of SERVICES) {
    if (host.includes(fragment)) return service;
  }
  return null;
}

function connect() {
  if (connecting || (socket && socket.readyState <= WebSocket.OPEN)) return;
  connecting = true;
  try {
    socket = new WebSocket(BOOTH_URL);
  } catch {
    connecting = false;
    return;
  }
  socket.onopen = () => {
    connecting = false;
    lastSentKey = "";
    socket.send(JSON.stringify({ token: "", role: "provider" }));
  };
  socket.onmessage = (event) => {
    let command = null;
    try {
      command = JSON.parse(event.data);
    } catch {
      return;
    }
    if (command && command.command) handleCommand(command);
  };
  socket.onclose = () => {
    connecting = false;
    socket = null;
    setTimeout(connect, RECONNECT_MS);
  };
  socket.onerror = () => {
    // onclose follows and schedules the retry.
  };
}

/** Largest entry in a Media Session artwork list; they're usually ascending but not guaranteed. */
function bestArtwork(artwork) {
  let best = null;
  let bestArea = -1;
  for (const art of artwork || []) {
    if (!art.src) continue;
    const match = /(\d+)\s*x\s*(\d+)/i.exec(art.sizes || "");
    const area = match ? Number(match[1]) * Number(match[2]) : 0;
    if (area > bestArea) {
      bestArea = area;
      best = art;
    }
  }
  return best;
}

async function fetchArtwork(src) {
  if (artworkCache.has(src)) return artworkCache.get(src);
  try {
    // Without a deadline a stalled image request would hang the caller.
    const response = await fetch(src, { signal: AbortSignal.timeout(8000) });
    if (!response.ok) return null;
    const buffer = await response.arrayBuffer();
    if (buffer.byteLength > MAX_ARTWORK_BYTES) return null;
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (let i = 0; i < bytes.length; i += 1) binary += String.fromCharCode(bytes[i]);
    const entry = {
      base64: btoa(binary),
      mimeType: response.headers.get("content-type") || "image/jpeg",
    };
    if (artworkCache.size > 30) artworkCache.clear();
    artworkCache.set(src, entry);
    return entry;
  } catch {
    return null;
  }
}

function buildMessage(payload, image) {
  return {
    kind: "meta",
    title: payload.title,
    artist: payload.artist,
    album: payload.album,
    service: serviceFor(payload.href),
    artworkBase64: image ? image.base64 : null,
    artworkMimeType: image ? image.mimeType : null,
    playing: payload.playbackState === "playing",
    pageURL: payload.href,
    likeStatus: payload.likeStatus || null,
    hasQueue: !!payload.hasQueue,
    debug: payload.debug || null,
  };
}

function sendMessage(message) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(message));
    return true;
  }
  return false;
}

function forward(payload) {
  connect();
  if (!socket || socket.readyState !== WebSocket.OPEN) return;

  const art = bestArtwork(payload.artwork);
  const key = `${payload.title}|${payload.artist}|${payload.playbackState}|${art ? art.src : ""}|${payload.likeStatus}|${payload.debug || ""}`;
  if (key === lastSentKey) return;
  lastSentKey = key;

  // Metadata goes out immediately; artwork is never allowed to gate it. A
  // slow or stalled image download would otherwise strand the whole payload,
  // and the dedupe key above would suppress every retry after it.
  const cached = art ? artworkCache.get(art.src) : null;
  sendMessage(buildMessage(payload, cached || null));
  if (!art || cached) return;

  fetchArtwork(art.src)
    .then((image) => {
      if (!image) return;
      // Only worth a follow-up if this is still the current payload.
      if (lastSentKey !== key) return;
      sendMessage(buildMessage(payload, image));
    })
    .catch(() => {});
}

/** Relays a phone-issued action to the playing tab and returns its reply. */
async function handleCommand({ command, index, tabId }) {
  // Source listing and switching are window-level, not tab-scoped.
  if (command === "listTabs") {
    // A suspended service worker loses tabStates, and content scripts only
    // re-report on change or a 10s heartbeat — so ask them to speak up rather
    // than answering with an empty list.
    if (tabStates.size === 0) await refreshTabStates();
    sendMessage({ kind: "tabs", tabs: listTabs() });
    return;
  }
  if (command === "activateTab") {
    if (tabId != null) await activateTab(tabId);
    return;
  }
  if (playingTabId == null) return;
  let reply = null;
  try {
    reply = await chrome.tabs.sendMessage(playingTabId, {
      type: "cueCommand",
      command,
      index,
    });
  } catch {
    playingTabId = null;
    return;
  }
  if (command === "requestQueue" && reply && reply.items) {
    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify({ kind: "queue", items: reply.items }));
    }
  }
  if (command === "toggleLike" || command === "toggleDislike") {
    // The DOM updates a beat after the click; let the next poll report it.
    lastSentKey = "";
  }
}

let reportedFirstPageMeta = false;

/** Smallest artwork entry — list rows only need a thumbnail. */
function smallestArtwork(artwork) {
  let best = null;
  let bestArea = Infinity;
  for (const art of artwork || []) {
    if (!art.src) continue;
    const match = /(\d+)\s*x\s*(\d+)/i.exec(art.sizes || "");
    const area = match ? Number(match[1]) * Number(match[2]) : 1e9;
    if (area < bestArea) {
      bestArea = area;
      best = art;
    }
  }
  return best ? best.src : null;
}

/** Ad iframes and muted autoplay embeds would swamp the list, so a tab has to
 *  look like real content: a title plus either a known service or artwork. */
function isListable(entry) {
  if (!entry || !entry.title || entry.title.length < 2) return false;
  return !!(entry.service || entry.artworkURL);
}

function listTabs() {
  return Array.from(tabStates.entries())
    .filter(([, entry]) => isListable(entry))
    .map(([tabId, entry]) => ({
      tabId,
      title: entry.title,
      subtitle: entry.subtitle || null,
      service: entry.service || null,
      playing: !!entry.playing,
      artworkURL: entry.artworkURL || null,
    }));
}

/** Prompts every tab to re-report, then waits briefly for the replies. */
async function refreshTabStates() {
  let tabs = [];
  try {
    tabs = await chrome.tabs.query({ url: ["http://*/*", "https://*/*"] });
  } catch {
    return;
  }
  await Promise.all(
    tabs.map((tab) =>
      tab.id == null
        ? Promise.resolve()
        : chrome.tabs
            .sendMessage(tab.id, { type: "cueCommand", command: "forceReport" })
            .catch(() => {})
    )
  );
  // page-reader polls at 1s; give it a beat to post.
  await new Promise((resolve) => setTimeout(resolve, 1400));
}

async function activateTab(tabId) {
  try {
    const tab = await chrome.tabs.get(tabId);
    await chrome.tabs.update(tabId, { active: true });
    if (tab.windowId != null) await chrome.windows.update(tab.windowId, { focused: true });
    // Starting playback is what makes macOS treat it as now-playing.
    const reply = await chrome.tabs.sendMessage(tabId, { type: "cueCommand", command: "play" });
    report(`activate tab ${tabId}: ${reply ? reply.how : "no reply"}`);
    playingTabId = tabId;
  } catch (error) {
    report(`activate tab ${tabId} failed: ${(error && error.message) || error}`);
    tabStates.delete(tabId);
  }
}

chrome.tabs.onRemoved.addListener((tabId) => {
  tabStates.delete(tabId);
  if (playingTabId === tabId) playingTabId = null;
});

chrome.runtime.onMessage.addListener((message, sender) => {
  if (!message || message.type !== "pageMeta") return;
  if (sender.tab && sender.tab.id != null) {
    tabStates.set(sender.tab.id, {
      title: message.payload.title,
      subtitle: message.payload.artist,
      service: serviceFor(message.payload.href),
      playing: message.payload.playbackState === "playing",
      artworkURL: smallestArtwork(message.payload.artwork),
    });
  }
  if (!reportedFirstPageMeta) {
    reportedFirstPageMeta = true;
    let host = "?";
    try {
      host = new URL(message.payload.href).hostname;
    } catch {}
    report(`first pageMeta from ${host} title="${message.payload.title}" state=${message.payload.playbackState}`);
  }
  if (message.payload.playbackState === "playing" && sender.tab) {
    playingTabId = sender.tab.id;
  } else if (playingTabId == null && sender.tab) {
    playingTabId = sender.tab.id;
  }
  forward(message.payload);
});

/** Content scripts are only injected on page load, so installing or reloading
 *  the extension would otherwise leave every open tab silent until reloaded. */
/** Programmatic injection, which unlike the manifest-declared content script
 *  reliably lands in the MAIN world on sites with a strict CSP. */
async function injectTab(tabId) {
  let ok = 0;
  let lastError = "";
  for (const [file, world] of [["page-reader.js", "MAIN"], ["bridge.js", "ISOLATED"]]) {
    try {
      await chrome.scripting.executeScript({
        target: { tabId, allFrames: true },
        files: [file],
        world,
      });
      ok += 1;
    } catch (error) {
      lastError = (error && error.message) || String(error);
    }
  }
  return { ok, lastError };
}

async function injectExistingTabs() {
  let tabs = [];
  try {
    tabs = await chrome.tabs.query({ url: ["http://*/*", "https://*/*"] });
  } catch (error) {
    report(`tabs.query failed: ${error && error.message}`);
    return;
  }
  let ok = 0;
  let failed = 0;
  for (const tab of tabs) {
    if (!tab.id) continue;
    const result = await injectTab(tab.id);
    ok += result.ok;
    failed += 2 - result.ok;
  }
  report(`injected ${ok} ok / ${failed} failed across ${tabs.length} tabs`);
}

// A tab reload re-runs only the manifest-declared scripts, which is not enough
// where MAIN-world injection is refused, so every completed load is injected
// explicitly as well.
chrome.tabs.onUpdated.addListener((tabId, info, tab) => {
  if (info.status !== "complete") return;
  if (!tab || !tab.url || !/^https?:/.test(tab.url)) return;
  injectTab(tabId);
});

/** Extension-side diagnostics are invisible from outside Chrome, so they're
 *  sent to Booth, which logs them. */
function report(message) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify({ kind: "meta", title: "", debug: `extension: ${message}` }));
  }
}

// Service workers get suspended; an alarm brings this one back to re-dial.
chrome.alarms.create("cue-keepalive", { periodInMinutes: 1 });
chrome.alarms.onAlarm.addListener(connect);
chrome.runtime.onStartup.addListener(() => {
  connect();
  injectExistingTabs();
});
chrome.runtime.onInstalled.addListener(() => {
  connect();
  injectExistingTabs();
});
connect();
// Give the socket a moment so the injection report has somewhere to go.
setTimeout(injectExistingTabs, 1200);
