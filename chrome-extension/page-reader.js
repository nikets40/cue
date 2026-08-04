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
