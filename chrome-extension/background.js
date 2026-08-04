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
    const response = await fetch(src);
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

async function forward(payload) {
  connect();
  if (!socket || socket.readyState !== WebSocket.OPEN) return;

  const art = bestArtwork(payload.artwork);
  const key = `${payload.title}|${payload.artist}|${payload.playbackState}|${art ? art.src : ""}|${payload.likeStatus}|${payload.debug || ""}`;
  if (key === lastSentKey) return;
  lastSentKey = key;

  const image = art ? await fetchArtwork(art.src) : null;
  const message = {
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
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(message));
  }
}

/** Relays a phone-issued action to the playing tab and returns its reply. */
async function handleCommand({ command, index }) {
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

chrome.runtime.onMessage.addListener((message, sender) => {
  if (!message || message.type !== "pageMeta") return;
  if (message.payload.playbackState === "playing" && sender.tab) {
    playingTabId = sender.tab.id;
  } else if (playingTabId == null && sender.tab) {
    playingTabId = sender.tab.id;
  }
  forward(message.payload);
});

/** Content scripts are only injected on page load, so installing or reloading
 *  the extension would otherwise leave every open tab silent until reloaded. */
async function injectExistingTabs() {
  let tabs = [];
  try {
    tabs = await chrome.tabs.query({ url: ["http://*/*", "https://*/*"] });
  } catch {
    return;
  }
  for (const tab of tabs) {
    if (!tab.id) continue;
    for (const [file, world] of [["page-reader.js", "MAIN"], ["bridge.js", "ISOLATED"]]) {
      chrome.scripting
        .executeScript({
          target: { tabId: tab.id, allFrames: true },
          files: [file],
          world,
        })
        .catch(() => {
          // Restricted page (chrome://, web store); nothing to do.
        });
    }
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
injectExistingTabs();
