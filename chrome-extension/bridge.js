// Isolated-world half of the pair: relays what page-reader.js sees in the
// page's realm to the service worker, and performs DOM actions the phone asks
// for. DOM work lives here rather than in the MAIN world because only the
// Media Session read needs the page's realm.

// Wrapped in an IIFE because this file is injected more than once into the
// same isolated world (manifest on page load, then again when the extension
// reloads) and top-level declarations would collide on the second pass.
(() => {

// Re-injection replaces the previous instance (see page-reader.js) so that
// reloading the extension updates open tabs instead of stacking listeners.
if (globalThis.__cueBridge) {
  window.removeEventListener("message", globalThis.__cueBridge.onWindowMessage);
  chrome.runtime.onMessage.removeListener(globalThis.__cueBridge.onRuntimeMessage);
}

function onWindowMessage(event) {
  if (event.source !== window) return;
  const message = event.data;
  if (!message || message.source !== "cue-page-reader") return;
  // Like state and queue presence come from the DOM, which only this world
  // can see, so they ride along with the Media Session payload.
  const payload = Object.assign({}, message.payload, {
    likeStatus: likeStatus(),
    hasQueue: queueItems().length > 0,
  });
  // sendMessage throws *synchronously* once the extension context is gone
  // (after a reload orphans this script), so .catch() alone doesn't cover it.
  try {
    const pending = chrome.runtime.sendMessage({ type: "pageMeta", payload });
    if (pending && pending.catch) pending.catch(() => {});
  } catch {
    // Orphaned by an extension reload; a fresh copy is injected separately.
  }
}
window.addEventListener("message", onWindowMessage);

// --- YouTube Music DOM (selectors verified against the live player) ---

function likeRenderer() {
  return document.querySelector("ytmusic-player-bar ytmusic-like-button-renderer");
}

/** "LIKE" | "DISLIKE" | "INDIFFERENT" -> lowercase, or null when unavailable. */
function likeStatus() {
  const status = likeRenderer()?.getAttribute("like-status");
  return status ? status.toLowerCase() : null;
}

function clickLike(which) {
  const renderer = likeRenderer();
  if (!renderer) return false;
  const label = which === "like" ? "Like" : "Dislike";
  const button = Array.from(renderer.querySelectorAll("button")).find(
    (b) => b.getAttribute("aria-label") === label
  );
  if (!button) return false;
  button.click();
  return true;
}

function queueItems() {
  const music = document.querySelectorAll("ytmusic-player-queue-item");
  if (music.length) return Array.from(music);
  // youtube.com mixes and playlists use a different row element.
  return Array.from(document.querySelectorAll("ytd-playlist-panel-video-renderer"));
}

/// Players expose their own jump buttons (Hotstar labels them "Rewind 10
/// seconds" / "Forward 10 seconds"). Clicking them is exact, where a relative
/// seek depends on a reported position that can drift badly on these sites.
function clickPlayerSkip(direction) {
  const pattern = direction === "forward"
    ? /forward|skip\s*ahead|jump\s*forward/i
    : /rewind|back\s*\d+|jump\s*back/i;
  const candidates = Array.from(
    document.querySelectorAll('button, [role="button"]')
  );
  for (const el of candidates) {
    const label = el.getAttribute("aria-label") || el.getAttribute("title") || "";
    // Guard against matching "Go to full screen" or a next-episode control.
    if (!pattern.test(label)) continue;
    if (/episode|screen|volume/i.test(label)) continue;
    el.click();
    return true;
  }
  return false;
}

/// Video fullscreen can't be entered from a script: requestFullscreen() needs
/// real user activation, and a synthetic click on the player's own button
/// doesn't grant it (verified — the call fails with a permissions error).
/// What is available is the site's own "wide"/theater layout, which is just a
/// CSS mode. Combined with fullscreening the browser window (done in
/// background.js, which has the API for it) the video ends up filling the
/// screen anyway.
function expandPlayer() {
  const selectors = [
    ".ytp-size-button",                          // youtube.com theater mode
    'button[aria-label*="full screen" i]',       // YouTube Music, Hotstar, Prime
    '[data-uia="control-fullscreen-enter"]',     // Netflix
  ];
  for (const selector of selectors) {
    const el = document.querySelector(selector);
    if (!el) continue;
    el.click();
    return { ok: true, how: selector };
  }
  return { ok: false, how: "no expand control" };
}

/// Moves keyboard focus onto the player so the "f" keystroke Booth sends next
/// reaches the video. Without this the key can land in a search field and just
/// type a letter. Focusing the player container is preferred over the <video>
/// element because that is where these sites bind their hotkeys.
function focusPlayer() {
  const containers = [
    "#movie_player",                      // youtube.com
    "ytmusic-player",                     // YouTube Music
    ".watch-video",                       // Netflix
    "video",
  ];
  for (const selector of containers) {
    const el = document.querySelector(selector);
    if (!el) continue;
    // Sites don't always mark their player focusable, and focus() is a no-op
    // without it.
    if (!el.hasAttribute("tabindex")) el.setAttribute("tabindex", "-1");
    el.focus({ preventScroll: true });
    if (document.activeElement === el) return { ok: true, how: selector };
  }
  // Better than leaving focus in a text field, where "f" would type a letter.
  if (document.activeElement && document.activeElement !== document.body) {
    document.activeElement.blur();
  }
  return { ok: false, how: "no player element" };
}

/// Netflix ignores the system next/previous commands, so episode changes have
/// to be driven from its own player controls.
function clickVideoSiteSkip(direction) {
  const selectors = direction === "next"
    ? ['[data-uia="control-next"]',
       '[data-uia="next-episode-seamless-button"]',
       '[data-uia="next-episode-seamless-button-draining"]',
       'button[aria-label*="Next episode" i]',
       'button[title*="Next episode" i]']
    : ['[data-uia="control-previous"]',
       'button[aria-label*="Previous episode" i]',
       'button[title*="Previous episode" i]'];
  for (const selector of selectors) {
    const button = document.querySelector(selector);
    if (button) {
      button.click();
      return true;
    }
  }
  return false;
}

/** Queue contents live on a JS property only the MAIN world can read, so
 *  page-reader.js builds the list and answers over window.postMessage. */
function readQueue(timeoutMs = 1500) {
  return new Promise((resolve) => {
    let settled = false;
    function onMessage(event) {
      if (event.source !== window) return;
      if (!event.data || event.data.source !== "cue-queue-response") return;
      settled = true;
      window.removeEventListener("message", onMessage);
      resolve(event.data.items || []);
    }
    window.addEventListener("message", onMessage);
    window.postMessage({ source: "cue-queue-request" }, "*");
    setTimeout(() => {
      if (settled) return;
      window.removeEventListener("message", onMessage);
      resolve([]);
    }, timeoutMs);
  });
}

/// Used when switching sources. A programmatic media.play() is often refused
/// by the autoplay policy, whereas clicking the player's own button counts as
/// a real activation, so the site's control is tried first.
function resumePlayback() {
  const media = document.querySelector("video, audio");
  if (media && !media.paused) return { ok: true, how: "already-playing" };

  const selectors = [
    ".ytp-play-button",                        // youtube.com
    "#play-pause-button",                      // YouTube Music
    '[data-uia="control-play-pause-play"]',    // Netflix
    'button[aria-label="Play"]',
    'button[title="Play"]',
  ];
  for (const selector of selectors) {
    const el = document.querySelector(selector);
    if (!el) continue;
    el.click();
    return { ok: true, how: `clicked ${selector}` };
  }
  if (media) {
    media.play().catch(() => {});
    return { ok: true, how: "media.play()" };
  }
  return { ok: false, how: "no player found" };
}

function playQueueIndex(index) {
  const items = queueItems();
  const item = items[index];
  if (!item) return false;
  const target =
    item.querySelector("#play-button") ||      // YouTube Music
    item.querySelector("a#wc-endpoint") ||     // youtube.com playlist panel
    item.querySelector(".song-title") ||
    item;
  target.click();
  return true;
}

function onRuntimeMessage(message, _sender, sendResponse) {
  if (!message || message.type !== "cueCommand") return;
  const { command, index } = message;
  switch (command) {
    case "toggleLike":
      sendResponse({ ok: clickLike("like"), likeStatus: likeStatus() });
      break;
    case "toggleDislike":
      sendResponse({ ok: clickLike("dislike"), likeStatus: likeStatus() });
      break;
    case "requestQueue":
      readQueue().then((items) => sendResponse({ ok: true, items }));
      break;
    case "playQueueItem":
      sendResponse({ ok: playQueueIndex(index) });
      break;
    case "nextTrack":
      sendResponse({ ok: clickVideoSiteSkip("next") });
      break;
    case "previousTrack":
      sendResponse({ ok: clickVideoSiteSkip("previous") });
      break;
    case "skipForward":
      sendResponse({ ok: clickPlayerSkip("forward") });
      break;
    case "skipBack":
      sendResponse({ ok: clickPlayerSkip("back") });
      break;
    case "play":
      sendResponse(resumePlayback());
      break;
    case "pause": {
      const media = document.querySelector("video, audio");
      if (media && !media.paused) media.pause();
      sendResponse({ ok: !!media });
      break;
    }
    case "expandPlayer":
      sendResponse(expandPlayer());
      break;
    case "focusPlayer":
      sendResponse(focusPlayer());
      break;
    case "forceReport":
      window.postMessage({ source: "cue-force-report" }, "*");
      sendResponse({ ok: true });
      break;
    default:
      sendResponse({ ok: false });
      break;
  }
  return true; // keep the channel open for the async queue reply
}
chrome.runtime.onMessage.addListener(onRuntimeMessage);

globalThis.__cueBridge = { onWindowMessage, onRuntimeMessage };

})();
