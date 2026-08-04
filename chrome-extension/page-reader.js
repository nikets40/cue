// Runs in the page's own JavaScript world. navigator.mediaSession.metadata is
// only visible to the realm that set it, so an isolated content script would
// read an empty session — hence "world": "MAIN" in the manifest. This script
// can't touch chrome.* APIs, so it posts to bridge.js instead.
(() => {
  // The manifest injects this on page load and background.js re-injects into
  // already-open tabs when the extension starts; only one loop should run.
  if (window.__cueReaderInstalled) return;
  window.__cueReaderInstalled = true;

  const POLL_MS = 1000;
  const HEARTBEAT_MS = 10000;
  let lastPayload = "";
  let lastPostAt = 0;

  function read() {
    const session = navigator.mediaSession;
    if (!session || !session.metadata) return null;
    const meta = session.metadata;
    return {
      title: meta.title || "",
      artist: meta.artist || "",
      album: meta.album || "",
      artwork: (meta.artwork || []).map((art) => ({
        src: art.src || "",
        sizes: art.sizes || "",
        type: art.type || "",
      })),
      playbackState: session.playbackState || "none",
      href: location.href,
    };
  }

  // --- Queue reading (MAIN world only) ---
  // Rows carry their real data — including thumbnail URLs at several sizes —
  // on a Polymer `data` property. The rendered <img> is a lazy-loading
  // placeholder until scrolled into view, and an isolated-world script can't
  // see JS properties at all, so the queue is read here and relayed out.

  function rowThumbnail(data, minWidth) {
    const list = (data && data.thumbnail && data.thumbnail.thumbnails) || [];
    const sorted = list.slice().sort((a, b) => a.width - b.width);
    const pick = sorted.find((t) => t.width >= minWidth) || sorted[sorted.length - 1];
    return pick ? pick.url : null;
  }

  function runsText(node) {
    if (!node || !node.runs) return null;
    return node.runs.map((r) => r.text).join("");
  }

  function parseDuration(text) {
    if (!text) return null;
    const parts = text.trim().split(":").map(Number);
    if (parts.some(Number.isNaN)) return null;
    return parts.reduce((total, part) => total * 60 + part, 0);
  }

  function readQueue() {
    return Array.from(document.querySelectorAll("ytmusic-player-queue-item")).map(
      (item, index) => {
        const data = item.data || {};
        // `data.selected` lands on several rows at once; the play button's
        // state is the only reliable marker of the row actually playing.
        const state = item.getAttribute("play-button-state");
        return {
          id: index,
          title: runsText(data.title) || "Untitled",
          subtitle: runsText(data.shortBylineText) || runsText(data.longBylineText),
          duration: parseDuration(runsText(data.lengthText)),
          isCurrent: state === "playing" || state === "paused",
          artworkURL: rowThumbnail(data, 120),
        };
      }
    );
  }

  window.addEventListener("message", (event) => {
    if (event.source !== window) return;
    if (!event.data || event.data.source !== "cue-queue-request") return;
    window.postMessage({ source: "cue-queue-response", items: readQueue() }, "*");
  });

  setInterval(() => {
    const payload = read();
    if (!payload) return;
    const key = JSON.stringify(payload);
    const stale = Date.now() - lastPostAt > HEARTBEAT_MS;
    // Re-post on a heartbeat even when nothing changed, so Booth recovers its
    // state after a restart instead of waiting for the next track.
    if (key === lastPayload && !stale) return;
    lastPayload = key;
    lastPostAt = Date.now();
    window.postMessage({ source: "cue-page-reader", payload }, "*");
  }, POLL_MS);
})();
