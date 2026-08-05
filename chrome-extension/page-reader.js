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
    // both put the programme name in the document title. Hotstar's reads
    // "Watch <Show> S2 Episode 2 on JioHotstar" — the platform suffix uses
    // "on", not a dash, and the episode has to be split off or a poster
    // lookup has nothing to match.
    const stripped = (document.title || "")
      .replace(/\s*[-|–]\s*(Netflix|Prime Video|Hotstar|JioHotstar|Disney\+\s*Hotstar)\s*$/i, "")
      .replace(/\s+on\s+(JioHotstar|Disney\+\s*Hotstar|Hotstar)\s*$/i, "")
      .replace(/^\s*(Watch|Prime Video:)\s*/i, "")
      .trim();
    if (!stripped || /^(netflix|prime video|hotstar|jiohotstar)$/i.test(stripped)) return null;

    const episode = stripped.match(
      /^(.*?)\s+S(?:eason\s*)?(\d+)\s*(?:Episode|Ep|E)\s*(\d+)\b\s*(.*)$/i);
    if (episode) {
      const trailing = episode[4] ? ` · ${episode[4].trim()}` : "";
      return {
        title: episode[1].trim(),
        subtitle: `S${episode[2]} · E${episode[3]}${trailing}`,
      };
    }
    return { title: stripped, subtitle: "" };
  }

  /// Reports which "next episode" controls a page exposes so a platform's
  /// skip button can be identified without guessing. Player chrome auto-hides
  /// on most services, so the richest result seen is remembered rather than
  /// whatever happens to be mounted at poll time.
  let bestSkipProbe = "";

  function collectDeep(root, out, depth) {
    if (depth > 4 || out.length > 12) return;
    let nodes = [];
    try {
      nodes = Array.from(root.querySelectorAll("button, [role=button], div, span, a"));
    } catch {
      return;
    }
    for (const el of nodes) {
      const label = [
        el.getAttribute && el.getAttribute("aria-label"),
        el.getAttribute && el.getAttribute("title"),
        el.getAttribute && el.getAttribute("data-testid"),
        typeof el.className === "string" ? el.className : "",
      ].filter(Boolean).join(" ");
      if (/next\s*ep|nextepisode|next-episode|skip.*intro|up\s*next/i.test(label)) {
        const tag = el.tagName.toLowerCase();
        const id = el.getAttribute("data-testid") || el.getAttribute("aria-label") || "";
        out.push(`${tag}:${id.slice(0, 28)}`);
        if (out.length > 12) return;
      }
      if (el.shadowRoot) collectDeep(el.shadowRoot, out, depth + 1);
    }
  }

  /// Identifies a control element compactly enough to log.
  function describe(el) {
    const parts = [
      el.getAttribute("aria-label"),
      el.getAttribute("data-testid"),
      el.getAttribute("title"),
      typeof el.className === "string" ? el.className.split(/\s+/)[0] : "",
    ].filter(Boolean);
    return (parts[0] || el.tagName.toLowerCase()).slice(0, 26).replace(/\s+/g, "_");
  }

  function probeSkipControls() {
    const hits = [];
    collectDeep(document, hits, 0);
    // Nothing matched the known patterns, so report what the player actually
    // has — the platform evidently names its controls something else.
    const buttons = Array.from(document.querySelectorAll("button")).map(describe);
    const host = Array.from(document.querySelectorAll("*")).find((e) => e.shadowRoot);
    let shadow = [];
    if (host && host.shadowRoot) {
      try {
        shadow = Array.from(host.shadowRoot.querySelectorAll("button, [role=button]"))
          .map(describe).slice(0, 8);
      } catch { /* closed root */ }
    }
    const probe = `skipHits=[${hits.join(" ")}] btns=[${buttons.slice(0, 12).join(",")}]`
      + ` shadow=[${shadow.join(",")}]`;
    if (hits.length || buttons.length > 2 || !bestSkipProbe) bestSkipProbe = probe;
    return bestSkipProbe;
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
        `resolved=${shown ? shown.title : "-"} sub=${shown ? shown.subtitle : "-"} ` +
        probeSkipControls(),
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

  /// YouTube Music and YouTube proper use different row elements but the same
  /// underlying data shape. They differ in how the playing row is marked:
  /// on Music `data.selected` lands on several rows at once so the play
  /// button's state is the only reliable signal, while on YouTube the
  /// `selected` attribute marks exactly one.
  function queueRows() {
    const musicRows = Array.from(document.querySelectorAll("ytmusic-player-queue-item"));
    if (musicRows.length) {
      return musicRows.map((item) => {
        const state = item.getAttribute("play-button-state");
        return { item, isCurrent: state === "playing" || state === "paused" };
      });
    }
    return Array.from(document.querySelectorAll("ytd-playlist-panel-video-renderer")).map(
      (item) => ({ item, isCurrent: item.hasAttribute("selected") })
    );
  }

  function textOf(node) {
    if (!node) return null;
    return runsText(node) || node.simpleText || null;
  }

  function readQueue() {
    return queueRows().map(({ item, isCurrent }, index) => {
      const data = item.data || {};
      return {
        id: index,
        title: textOf(data.title) || "Untitled",
        subtitle: textOf(data.shortBylineText) || textOf(data.longBylineText),
        duration: parseDuration(textOf(data.lengthText)),
        isCurrent,
        artworkURL: rowThumbnail(data, 120),
      };
    });
  }

  function onQueueRequest(event) {
    if (event.source !== window) return;
    if (!event.data) return;
    if (event.data.source === "cue-force-report") {
      // The service worker lost its tab list (MV3 suspends it); clearing the
      // dedupe key makes the next poll re-report instead of waiting for the
      // heartbeat.
      lastPayload = "";
      lastPostAt = 0;
      return;
    }
    if (event.data.source !== "cue-queue-request") return;
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
