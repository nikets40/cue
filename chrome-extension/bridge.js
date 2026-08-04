// Isolated-world half of the pair: relays what page-reader.js sees in the
// page's realm to the service worker, and performs DOM actions the phone asks
// for. DOM work lives here rather than in the MAIN world because only the
// Media Session read needs the page's realm.

window.addEventListener("message", (event) => {
  if (event.source !== window) return;
  const message = event.data;
  if (!message || message.source !== "cue-page-reader") return;
  // Like state and queue presence come from the DOM, which only this world
  // can see, so they ride along with the Media Session payload.
  const payload = Object.assign({}, message.payload, {
    likeStatus: likeStatus(),
    hasQueue: queueItems().length > 0,
  });
  chrome.runtime.sendMessage({ type: "pageMeta", payload }).catch(() => {
    // Service worker asleep or reloading; the next poll will retry.
  });
});

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
  return Array.from(document.querySelectorAll("ytmusic-player-queue-item"));
}

/** The current row is the one whose play button is playing or paused;
 *  the `selected` attribute lands on several rows and can't be trusted. */
function isCurrent(item) {
  const state = item.getAttribute("play-button-state");
  return state === "playing" || state === "paused";
}

function parseDuration(text) {
  if (!text) return null;
  const parts = text.trim().split(":").map(Number);
  if (parts.some(Number.isNaN)) return null;
  return parts.reduce((total, part) => total * 60 + part, 0);
}

function readQueue() {
  return queueItems().map((item, index) => {
    const columns = Array.from(item.querySelectorAll("yt-formatted-string")).map((e) =>
      e.textContent.trim()
    );
    return {
      id: index,
      title: item.querySelector(".song-title")?.textContent.trim() || columns[0] || "Untitled",
      duration: parseDuration(columns.find((c) => /^\d+:\d{2}$/.test(c))),
      isCurrent: isCurrent(item),
    };
  });
}

function playQueueIndex(index) {
  const items = queueItems();
  const item = items[index];
  if (!item) return false;
  const target =
    item.querySelector("#play-button") || item.querySelector(".song-title") || item;
  target.click();
  return true;
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || message.type !== "cueCommand") return;
  const { command, index } = message;
  let result = { ok: false };
  switch (command) {
    case "toggleLike":
      result = { ok: clickLike("like"), likeStatus: likeStatus() };
      break;
    case "toggleDislike":
      result = { ok: clickLike("dislike"), likeStatus: likeStatus() };
      break;
    case "requestQueue":
      result = { ok: true, items: readQueue() };
      break;
    case "playQueueItem":
      result = { ok: playQueueIndex(index) };
      break;
    default:
      break;
  }
  sendResponse(result);
  return true;
});
