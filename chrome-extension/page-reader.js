// Runs in the page's own JavaScript world. navigator.mediaSession.metadata is
// only visible to the realm that set it, so an isolated content script would
// read an empty session — hence "world": "MAIN" in the manifest. This script
// can't touch chrome.* APIs, so it posts to bridge.js instead.
(() => {
  const POLL_MS = 1000;
  let lastPayload = "";

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
    if (key === lastPayload) return;
    lastPayload = key;
    window.postMessage({ source: "cue-page-reader", payload }, "*");
  }, POLL_MS);
})();
