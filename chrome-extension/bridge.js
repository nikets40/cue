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
    default:
      sendResponse({ ok: false });
      break;
  }
  return true; // keep the channel open for the async queue reply
});
