import { CuePhone } from "./phone";
import { CueWatch } from "./watch";
import { Reveal } from "./reveal";

const GITHUB = "https://github.com/nikets40/cue";
// Resolves to whatever the newest release holds, so long as the asset keeps
// this name — see tools/make-release.sh.
const DOWNLOAD = "https://github.com/nikets40/cue/releases/latest/download/CueBooth.zip";

const brands = [
  ["netflix.svg", "Netflix"],
  ["youtube.svg", "YouTube"],
  ["ytmusic.svg", "YouTube Music"],
  ["prime.svg", "Prime Video"],
  ["hotstar.svg", "Hotstar"],
  ["spotify.svg", "Spotify"],
  ["vlc.png", "VLC"],
] as const;

export function Hero() {
  return (
    <header className="v3-hero" id="top">
      {/* ambient sunset light */}
      <div
        className="v3-orb"
        style={{ width: 980, height: 680, top: -120, left: "50%", transform: "translateX(-38%)" }}
      />
      <div className="v3-hero-grid">
        <div style={{ display: "flex", flexDirection: "column", gap: 26, position: "relative", zIndex: 1 }}>
          <Reveal>
            <span
              className="v3-chip"
              style={{ height: 34, fontSize: 12.5, gap: 7 }}
            >
              <span
                style={{
                  width: 7,
                  height: 7,
                  borderRadius: 4,
                  background: "var(--ok-green)",
                }}
              />
              Local-only · Open source · MIT
            </span>
          </Reveal>
          <Reveal>
            <h1 className="v3-display v3-h1">
              The remote your Mac never&nbsp;had.
            </h1>
          </Reveal>
          <Reveal>
            <p className="v3-lead" style={{ maxWidth: 500 }}>
              Cue turns your iPhone — and your wrist — into a real remote for
              everything playing on your Mac: Netflix, YouTube&nbsp;Music,
              Prime, VLC, QuickTime, any browser tab. Real posters, real
              titles, over your own Wi-Fi.
            </p>
          </Reveal>
          <Reveal>
            <div style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "center" }}>
              <a className="v3-btn v3-btn-primary" href={DOWNLOAD}>
                Download for macOS
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                  <path d="M12 4v12m0 0 4-4m-4 4-4-4M5 20h14" />
                </svg>
              </a>
              <a className="v3-btn v3-btn-ghost" href={GITHUB} target="_blank" rel="noreferrer">
                Source on GitHub
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                  <path d="M7 17 17 7M9 7h8v8" />
                </svg>
              </a>
              <a className="v3-btn v3-btn-ghost" href="#get-cue">
                Or buy it ready-made
                <span
                  style={{
                    fontSize: 11,
                    fontWeight: 700,
                    letterSpacing: "0.06em",
                    textTransform: "uppercase",
                    background: "var(--grad-brand)",
                    WebkitBackgroundClip: "text",
                    backgroundClip: "text",
                    color: "transparent",
                  }}
                >
                  soon
                </span>
              </a>
            </div>
          </Reveal>
          <Reveal>
            {/* The download is the Mac half only. Saying so here costs a line
                and saves someone downloading it expecting a phone app. */}
            <p style={{ fontSize: 12.5, color: "var(--text-muted)", lineHeight: 1.6, maxWidth: "46ch" }}>
              macOS 14+. Free and open source. The iPhone and Watch apps are
              built and installed with Xcode —{" "}
              <a
                href={`${GITHUB}#3-build-and-install-the-iphone-app`}
                target="_blank"
                rel="noreferrer"
                style={{ color: "var(--text-secondary)", textDecoration: "underline" }}
              >
                see the guide
              </a>
              .
            </p>
          </Reveal>
          <Reveal>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <span style={{ fontSize: 12.5, color: "var(--text-muted)", fontWeight: 500 }}>
                One remote for all of it
              </span>
              <div className="v3-brand-row">
                {brands.map(([file, name]) => (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img key={file} src={`/brands/${file}`} alt={name} title={name} />
                ))}
              </div>
            </div>
          </Reveal>
        </div>

        <Reveal dir="sc">
          <div className="v3-hero-phone-box">
            {/* artwork glow behind the phone */}
            <div
              style={{
                position: "absolute",
                width: 380,
                height: 380,
                borderRadius: "50%",
                background:
                  "radial-gradient(closest-side, rgba(244,87,46,0.28), rgba(217,50,122,0.18) 55%, transparent)",
                filter: "blur(34px)",
              }}
            />
            <CuePhone />

            {/* floating: source switcher */}
            <div className="v3-widget v3-flt" style={{ top: 64, left: -34, width: 212 }}>
              <div style={{ fontSize: 11.5, fontWeight: 700, letterSpacing: "0.07em", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: 9 }}>
                Sources · 3 open
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
                {[
                  ["The Long Static", "Netflix · playing", true],
                  ["clip_004.mov", "QuickTime · paused", false],
                  ["Bassline.flac", "VLC · paused", false],
                ].map(([title, sub, active]) => (
                  <div key={title as string} className="v3-mini-row" style={{ padding: "6px 9px" }}>
                    <span
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: 4,
                        background: active ? "var(--ok-green)" : "var(--text-faint)",
                        flexShrink: 0,
                      }}
                    />
                    <span style={{ minWidth: 0 }}>
                      <span style={{ display: "block", fontSize: 12.5, fontWeight: 600, color: "var(--text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                        {title}
                      </span>
                      <span style={{ display: "block", fontSize: 11, color: "var(--text-muted)" }}>{sub}</span>
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* floating: fullscreen toast */}
            <div
              className="v3-widget v3-flt"
              style={{ top: 210, right: -26, display: "flex", alignItems: "center", gap: 10, animationDelay: "1.6s" }}
            >
              <span
                style={{
                  width: 26,
                  height: 26,
                  borderRadius: 14,
                  background: "var(--ok-green-soft)",
                  color: "var(--ok-green)",
                  display: "inline-flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m4 12 5 5L20 6" />
                </svg>
              </span>
              <span style={{ fontSize: 13, fontWeight: 600, color: "var(--text-strong)" }}>
                Fullscreen, on the Mac
              </span>
            </div>

            {/* floating: live activity */}
            <div
              className="v3-widget v3-flt"
              style={{
                bottom: 58,
                left: -18,
                width: 232,
                background: "#1a1922",
                boxShadow: "var(--shadow-xl)",
                animationDelay: "3.1s",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 11 }}>
                <span
                  style={{
                    width: 34,
                    height: 34,
                    borderRadius: 9,
                    flexShrink: 0,
                    background: "linear-gradient(140deg, #f7941e, #d9327a 70%, #5b2bb8)",
                  }}
                />
                <span style={{ minWidth: 0 }}>
                  <span style={{ display: "block", fontSize: 12.5, fontWeight: 600, color: "#f2ede4", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                    Midnight Reverie
                  </span>
                  <span style={{ display: "block", fontSize: 11, color: "rgba(242,237,228,0.55)" }}>
                    Lock Screen · ticking
                  </span>
                </span>
              </div>
              <div style={{ marginTop: 10, height: 3.5, borderRadius: 2, background: "rgba(242,237,228,0.14)", position: "relative", overflow: "hidden" }}>
                <span style={{ position: "absolute", inset: "0 auto 0 0", width: "34%", background: "linear-gradient(90deg,#f7941e,#e0447c)", borderRadius: 2 }} />
              </div>
            </div>

            {/* floating: watch companion, slightly overlapping the phone */}
            <div
              className="v3-hero-float v3-flt"
              style={{ bottom: 8, right: -40, animationDelay: "4.4s" }}
            >
              <div style={{ transform: "scale(0.82)", transformOrigin: "bottom right" }}>
                <CueWatch />
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </header>
  );
}
