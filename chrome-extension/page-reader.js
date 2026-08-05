// Runs in the page's own JavaScript world. navigator.mediaSession.metadata is
// only visible to the realm that set it, so an isolated content script would
// read an empty session — hence "world": "MAIN" in the manifest. This script
// can't touch chrome.* APIs, so it posts to bridge.js instead.
(() => {
  // The manifest injects this on page load and background.js re-injects into
  // already-open tabs when the extension starts. Tear down any previous
  // instance rather than bailing out, so reloading the extension actually
  // replaces the running code instead of leaving the old version in place.
  if (window.__cueReader) {
    clearInterval(window.__cueReader.timer);
    window.removeEventListener("message", window.__cueReader.onQueueRequest);
  }

  const POLL_MS = 1000;
  const HEARTBEAT_MS = 10000;
  let lastPayload = "";
  let lastPostAt = 0;

  /// Video platforms publish a generic Media Session title — Netflix reports
  /// literally "Netflix" — so the real show name has to come from the player
  /// UI. Returns { title, subtitle } where title is the series/film name
  /// suitable for a poster lookup, and subtitle carries episode detail.
  // Netflix only mounts its title overlay while the player controls are
  // visible, and they auto-hide after a few seconds. Whatever is seen is
  // remembered per URL so the name survives the controls disappearing.
  const stickyTitles = new Map();

  function netflixTitle() {
    const box = document.querySelector('[data-uia="video-title"]');
    if (!box) return null;
    const series = box.querySelector("h4");
    const detail = Array.from(box.querySelectorAll("span"))
      .map((s) => s.textContent.trim())
      .filter(Boolean);
    if (series && series.textContent.trim()) {
      return { title: series.textContent.trim(), subtitle: detail.join(" · ") };
    }
    const text = box.textContent.trim();
    return text ? { title: text, subtitle: "" } : null;
  }

  function videoSiteTitle() {
    const host = location.hostname;
    const stickyKey = location.pathname;

    if (host.includes("netflix.")) {
      const live = netflixTitle();
      if (live) {
        stickyTitles.set(stickyKey, live);
        return live;
      }
      const remembered = stickyTitles.get(stickyKey);
      if (remembered) return remembered;
    }

    // Hotstar and Prime Video don't expose a stable player-title hook, but
    // both put the programme name in the document title.
    const stripped = (document.title || "")
      .replace(/\s*[-|–]\s*(Netflix|Prime Video|Hotstar|JioHotstar|Disney\+ Hotstar)\s*$/i, "")
      .replace(/^\s*(Watch|Prime Video:)\s*/i, "")
      .trim();
    if (stripped && !/^(netflix|prime video|hotstar|jiohotstar)$/i.test(stripped)) {
      return { title: stripped, subtitle: "" };
    }
    return null;
  }

  /// Streaming sites that don't publish Media Session data still need to be
  /// identified, or the phone has no platform logo to fall back to. A playing
  /// <video> plus the document title is enough to name the source.
  function readVideoFallback() {
    const video = Array.from(document.querySelectorAll("video")).find(
      (v) => !v.paused && v.readyState > 2 && v.duration > 0
    );
    if (!video) return null;
    // Netflix takes this path — it publishes no Media Session metadata at all,
    // and its document title is just "Netflix", so the programme name has to
    // come from the player UI here too.
    const shown = videoSiteTitle();
    return {
      title: shown ? shown.title : "",
      artist: shown ? shown.subtitle : "",
      album: "",
      artwork: [],
      playbackState: "playing",
      href: location.href,
      debug: `noMediaSession docTitle=${document.title || "-"} ` +
        `videoTitleEl=${!!document.querySelector('[data-uia="video-title"]')} ` +
        `resolved=${shown ? shown.title : "-"}`,
    };
  }

  const VIDEO_HOSTS = /(netflix\.|hotstar\.|primevideo\.|amazon\.)/;

  function read() {
    const session = navigator.mediaSession;
    if (!session || !session.metadata) return readVideoFallback();
    const meta = session.metadata;

    // On video platforms the session title is the brand, not the programme.
    let title = meta.title || "";
    let artist = meta.artist || "";
    if (VIDEO_HOSTS.test(location.hostname)) {
      const shown = videoSiteTitle();
      if (shown && shown.title) {
        title = shown.title;
        artist = shown.subtitle || artist;
      }
    }

    return {
      title,
      artist,
      // Temporary: lets Booth log what the page actually exposes when a
      // platform's title can't be resolved.
      debug: VIDEO_HOSTS.test(location.hostname)
        ? `msTitle=${meta.title || "-"} docTitle=${document.title || "-"} ` +
          `videoTitleEl=${!!document.querySelector('[data-uia="video-title"]')}`
        : undefined,
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

  function onQueueRequest(event) {
    if (event.source !== window) return;
    if (!event.data || event.data.source !== "cue-queue-request") return;
    window.postMessage({ source: "cue-queue-response", items: readQueue() }, "*");
  }
  window.addEventListener("message", onQueueRequest);

  const timer = setInterval(() => {
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

  window.__cueReader = { timer, onQueueRequest };
})();
