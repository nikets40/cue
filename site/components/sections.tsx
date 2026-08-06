import { Reveal } from "./reveal";
import { Faq } from "./faq";
import { CueWatch } from "./watch";

const GITHUB = "https://github.com/nikets40/cue";

function Check() {
  return <span className="v3-check">✓</span>;
}

/* ============ Sources ============ */

export function Sources() {
  return (
    <div className="v3-panel-band" id="sources" style={{ paddingTop: 48 }}>
      <div className="v3-panel" style={{ background: "var(--tint-sand)" }}>
        <div className="v3-orb" style={{ width: 640, height: 520, right: -180, top: -120, opacity: 0.5 }} />
        <div className="v3-panel-pad v3-split">
          <Reveal dir="l">
            <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
              <span className="v3-eyebrow">Every source, one list</span>
              <h2 className="v3-display v3-h2">Everything open. One tap away.</h2>
              <p className="v3-lead">
                macOS only admits to one now-playing app at a time. Cue sees them
                all — every Chrome tab holding media, every QuickTime window,
                whatever VLC has loaded — playing or paused, with real
                thumbnails.
              </p>
              <ul className="v3-check-list">
                <li>
                  <Check />
                  Paused tabs included — the ones macOS forgets about entirely
                </li>
                <li>
                  <Check />
                  Tap to switch: Cue pauses the rest, raises the window, presses play
                </li>
                <li>
                  <Check />
                  Ad iframes filtered out, so the list is only real media
                </li>
              </ul>
            </div>
          </Reveal>
          <Reveal dir="r">
            {/* the phone bleeds off the panel's bottom edge; the panel's
                overflow:hidden does the cropping */}
            <div style={{ display: "flex", justifyContent: "center", marginBottom: -290 }}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="/screenshots/sources.png"
                alt="Cue's source picker listing browser tabs, QuickTime and VLC"
                width={330}
                height={653}
                style={{ width: 330, height: "auto", filter: "drop-shadow(0 24px 48px rgba(28,23,18,0.28))" }}
              />
            </div>
          </Reveal>
        </div>
      </div>
    </div>
  );
}

/* ============ Artwork: before / after ============ */

export function Artwork() {
  return (
    <section className="v3-section">
      <div className="v3-wrap" style={{ display: "flex", flexDirection: "column", gap: 44 }}>
        <Reveal>
          <div style={{ maxWidth: 560, display: "flex", flexDirection: "column", gap: 16 }}>
            <span className="v3-eyebrow">Real posters, real titles</span>
            <h2 className="v3-display v3-h2">It knows what show you&rsquo;re watching.</h2>
            <p className="v3-lead">
              Netflix tells your Mac its name is &ldquo;Netflix&rdquo; and hands
              over no artwork at all. Cue reads the actual title off the player,
              remembers it when the controls fade, and finds the real poster —
              shown at its native 2:3, never cropped.
            </p>
          </div>
        </Reveal>
        <Reveal stagger={120} className="v3-split" >
          {/* before */}
          <div
            style={{
              background: "var(--surface-card)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "var(--radius-xl)",
              padding: 30,
              boxShadow: "var(--shadow-xs)",
            }}
          >
            <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: 20 }}>
              What macOS sees
            </div>
            <div style={{ display: "flex", gap: 18, alignItems: "center" }}>
              <div
                style={{
                  width: 116,
                  height: 116,
                  borderRadius: 14,
                  background: "var(--bg-sunken)",
                  border: "1px dashed var(--border-default)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "var(--text-faint)",
                }}
              >
                <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
                  <rect x="3" y="3" width="18" height="18" rx="3" />
                  <circle cx="9" cy="9" r="2" />
                  <path d="m3 17 5-5 4 4 3-3 6 6" />
                </svg>
              </div>
              <div>
                <div style={{ fontFamily: "var(--font-display)", fontSize: 22, fontWeight: 620, color: "var(--text-strong)" }}>
                  Netflix
                </div>
                <div style={{ fontSize: 13.5, color: "var(--text-muted)", marginTop: 4 }}>
                  Google Chrome · no artwork
                </div>
              </div>
            </div>
          </div>
          {/* after */}
          <div
            style={{
              background: "var(--surface-card)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "var(--radius-xl)",
              padding: 30,
              boxShadow: "var(--shadow-md)",
            }}
          >
            <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--sun-magenta)", marginBottom: 20 }}>
              What Cue shows
            </div>
            <div style={{ display: "flex", gap: 18, alignItems: "center" }}>
              <div
                style={{
                  width: 116,
                  height: 174,
                  borderRadius: 12,
                  flexShrink: 0,
                  position: "relative",
                  overflow: "hidden",
                  background: "linear-gradient(165deg, #2a2440 0%, #4a2545 45%, #b3452c 80%, #f7941e 100%)",
                  boxShadow: "var(--shadow-lg)",
                }}
              >
                <div style={{ position: "absolute", inset: 0, background: "radial-gradient(70% 40% at 50% 12%, rgba(255,220,170,0.5), transparent 70%)" }} />
                <div
                  style={{
                    position: "absolute",
                    left: 0,
                    right: 0,
                    bottom: 12,
                    textAlign: "center",
                    fontFamily: "var(--font-display)",
                    fontSize: 13,
                    fontWeight: 700,
                    letterSpacing: "0.09em",
                    textTransform: "uppercase",
                    color: "#f6ecda",
                  }}
                >
                  The Long
                  <br />
                  Static
                </div>
              </div>
              <div>
                <div style={{ fontFamily: "var(--font-display)", fontSize: 22, fontWeight: 620, color: "var(--text-strong)" }}>
                  The Long Static
                </div>
                <div className="v3-mono" style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 5 }}>
                  S2 · E4 — Signal to Noise
                </div>
                <div style={{ fontSize: 13.5, color: "var(--text-body)", marginTop: 10, lineHeight: 1.5 }}>
                  Poster fetched, title read off the player, remembered when the
                  controls fade.
                </div>
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* ============ Fullscreen: the dark stage ============ */

export function Fullscreen() {
  return (
    <div className="v3-panel-band" id="fullscreen">
      <div className="v3-panel v3-stage-panel">
        <div className="v3-orb" style={{ width: 700, height: 560, right: -160, top: -160, opacity: 0.9 }} />
        <div className="v3-panel-pad" style={{ display: "flex", flexDirection: "column", gap: 40 }}>
          <Reveal>
            <div style={{ maxWidth: 620, display: "flex", flexDirection: "column", gap: 16 }}>
              <span className="v3-eyebrow">The hard part</span>
              <h2 className="v3-display v3-h2">
                Netflix from the couch. Actually&nbsp;fullscreen.
              </h2>
              <p className="v3-lead">
                No extension can fullscreen a browser video — Chrome only trusts
                a real keypress. So Cue makes one.
              </p>
            </div>
          </Reveal>
          <Reveal stagger={120} className="v3-steps">
            {[
              {
                n: "01",
                t: "Focus the player",
                c: "The extension raises the right window, activates the right tab, and puts keyboard focus on the video itself.",
              },
              {
                n: "02",
                t: "Press the key",
                c: "The Mac app posts a genuine keystroke — f — through the system's own input stack, not the page.",
              },
              {
                n: "03",
                t: "The page believes it",
                c: "Indistinguishable from your keyboard. The player's own listener reports it, verified:",
                chip: "isTrusted: true",
              },
            ].map((s) => (
              <div
                key={s.n}
                style={{
                  background: "rgba(255,255,255,0.045)",
                  border: "1px solid rgba(255,255,255,0.09)",
                  borderRadius: "var(--radius-lg)",
                  padding: "24px 22px",
                  display: "flex",
                  flexDirection: "column",
                  gap: 10,
                }}
              >
                <span className="v3-step-num">{s.n}</span>
                <span style={{ fontFamily: "var(--font-display)", fontSize: 20, fontWeight: 620, color: "var(--text-on-dark)" }}>
                  {s.t}
                </span>
                <span className="v3-stage-body" style={{ fontSize: 14.5, lineHeight: 1.55 }}>
                  {s.c}
                </span>
                {s.chip && <span className="v3-code-chip" style={{ width: "fit-content" }}>{s.chip}</span>}
              </div>
            ))}
          </Reveal>
          <Reveal>
            <p className="v3-stage-body" style={{ fontSize: 13.5, margin: 0 }}>
              One key covers YouTube, Netflix, Prime and Hotstar. QuickTime and
              VLC go fullscreen natively — and VLC is deliberately left alone on
              audio-only items, so it never surprises you on the next video.
            </p>
          </Reveal>
        </div>
      </div>
    </div>
  );
}

/* ============ Watch ============ */

export function Watch() {
  return (
    <div className="v3-panel-band" id="watch">
      <div className="v3-panel" style={{ background: "var(--tint-mint)" }}>
        <div className="v3-orb" style={{ width: 620, height: 500, left: -160, bottom: -160, opacity: 0.45 }} />
        <div className="v3-panel-pad v3-split">
          <Reveal dir="l">
            <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
              <span className="v3-eyebrow">New · Apple Watch</span>
              <h2 className="v3-display v3-h2">Now on your wrist.</h2>
              <p className="v3-lead">
                A deliberately small watch app: what&rsquo;s playing, play/pause,
                ±15s — and the Digital Crown turns your Mac&rsquo;s volume, with
                haptic ticks. It relays through your iPhone, so there is nothing
                new to pair.
              </p>
              <ul className="v3-check-list">
                <li>
                  <Check />
                  Digital Crown is a volume knob for your Mac
                </li>
                <li>
                  <Check />
                  Real artwork, resized to what a watch can actually resolve
                </li>
                <li>
                  <Check />
                  Progress ticks locally — a playing track costs zero transfers
                </li>
              </ul>
              <p style={{ margin: 0, fontSize: 13.5, color: "var(--text-muted)" }}>
                No queue, no source picker — on a watch, those are worse than
                reaching for your phone. So they aren&rsquo;t there.
              </p>
            </div>
          </Reveal>
          <Reveal dir="sc">
            <div style={{ display: "flex", justifyContent: "center", position: "relative", padding: "24px 0" }}>
              <div
                style={{
                  position: "absolute",
                  width: 300,
                  height: 300,
                  borderRadius: "50%",
                  background:
                    "radial-gradient(closest-side, rgba(244,87,46,0.2), rgba(124,58,237,0.12) 60%, transparent)",
                  filter: "blur(30px)",
                }}
              />
              <CueWatch />
            </div>
          </Reveal>
        </div>
      </div>
    </div>
  );
}

/* ============ Bento ============ */

export function Bento() {
  return (
    <section className="v3-section">
      <div className="v3-wrap" style={{ display: "flex", flexDirection: "column", gap: 40 }}>
        <Reveal>
          <div style={{ maxWidth: 520, display: "flex", flexDirection: "column", gap: 16 }}>
            <span className="v3-eyebrow">And the rest</span>
            <h2 className="v3-display v3-h2">Small things, done properly.</h2>
          </div>
        </Reveal>
        <Reveal stagger={85} className="v3-bento">
          <div className="v3-bento-card">
            <h3 className="v3-bento-title">Up Next, browsable</h3>
            <p className="v3-bento-copy">
              YouTube Music and YouTube playlists with artwork, artists and
              durations — verified at 207 rows. VLC&rsquo;s playlist rides the
              same rails.
            </p>
            <div className="v3-bento-vignette" style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              {[
                ["Midnight Reverie", "3:36", true],
                ["Glasshouse", "4:02", false],
                ["Second Sun", "2:58", false],
              ].map(([t, d, on]) => (
                <div key={t as string} className="v3-mini-row">
                  <span
                    style={{
                      width: 26,
                      height: 26,
                      borderRadius: 6,
                      flexShrink: 0,
                      background: on
                        ? "linear-gradient(140deg,#f7941e,#d9327a)"
                        : "var(--ink-150)",
                    }}
                  />
                  <span style={{ fontSize: 12.5, fontWeight: 600, color: "var(--text-strong)", flex: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                    {t}
                  </span>
                  <span className="v3-mono" style={{ fontSize: 11, color: "var(--text-muted)" }}>{d}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="v3-bento-card">
            <h3 className="v3-bento-title">On your Lock Screen</h3>
            <p className="v3-bento-copy">
              A Live Activity with working buttons and a progress bar that keeps
              ticking — no push service, no paid developer account. Dynamic
              Island included.
            </p>
            <div className="v3-bento-vignette">
              <div
                style={{
                  background: "#16141d",
                  borderRadius: 16,
                  padding: "12px 14px",
                  display: "flex",
                  alignItems: "center",
                  gap: 11,
                }}
              >
                <span style={{ width: 30, height: 30, borderRadius: 8, flexShrink: 0, background: "linear-gradient(140deg,#f7941e,#d9327a 70%,#5b2bb8)" }} />
                <span style={{ flex: 1, minWidth: 0 }}>
                  <span style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#f2ede4" }}>Midnight Reverie</span>
                  <span className="v3-progress" style={{ marginTop: 7, background: "rgba(242,237,228,0.14)" }}>
                    <span />
                  </span>
                </span>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="#f2ede4" aria-hidden>
                  <rect x="6" y="4" width="4" height="16" rx="1.5" />
                  <rect x="14" y="4" width="4" height="16" rx="1.5" />
                </svg>
              </div>
            </div>
          </div>

          <div className="v3-bento-card">
            <h3 className="v3-bento-title">Real volume buttons</h3>
            <p className="v3-bento-copy">
              Press the iPhone&rsquo;s physical volume keys and the Mac&rsquo;s
              volume moves — through CoreAudio directly, because the AppleScript
              route lagged 200&nbsp;ms per call.
            </p>
            <div className="v3-bento-vignette">
              <div className="v3-mini-row" style={{ gap: 12 }}>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="var(--text-muted)" aria-hidden>
                  <path d="M4 9v6h4l5 4V5L8 9H4zm12.5 3a4.5 4.5 0 0 0-2.5-4v8a4.5 4.5 0 0 0 2.5-4z" />
                </svg>
                <div className="v3-progress" style={{ flex: 1 }}>
                  <span style={{ width: "52%", animation: "none" }} />
                </div>
                <span className="v3-mono" style={{ fontSize: 11.5, color: "var(--text-muted)" }}>52%</span>
              </div>
            </div>
          </div>

          <div className="v3-bento-card">
            <h3 className="v3-bento-title">+15 means +15</h3>
            <p className="v3-bento-copy">
              macOS&rsquo;s idea of playback position can drift 15 seconds on
              Netflix. Cue reads the video element&rsquo;s real clock, ages it
              forward, and seeks to the exact second.
            </p>
            <div className="v3-bento-vignette">
              <div className="v3-mini-row v3-mono" style={{ justifyContent: "space-between", fontSize: 12 }}>
                <span style={{ color: "var(--text-muted)" }}>skip via macOS</span>
                <span style={{ color: "var(--sun-coral)", fontWeight: 600 }}>−84 s off</span>
              </div>
              <div className="v3-mini-row v3-mono" style={{ justifyContent: "space-between", fontSize: 12, marginTop: 6 }}>
                <span style={{ color: "var(--text-muted)" }}>skip via Cue</span>
                <span style={{ color: "var(--ok-green)", fontWeight: 600 }}>±0 s</span>
              </div>
            </div>
          </div>

          <div className="v3-bento-card">
            <h3 className="v3-bento-title">Like from the couch</h3>
            <p className="v3-bento-copy">
              Thumbs up and down on YouTube Music, reflecting the page&rsquo;s
              real state — filled when it&rsquo;s liked, hollow when it
              isn&rsquo;t.
            </p>
            <div className="v3-bento-vignette" style={{ display: "flex", gap: 8 }}>
              <span className="v3-mini-row" style={{ padding: "9px 14px", color: "var(--sun-magenta)" }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                  <path d="M2 10h4v11H2zM22 10a2 2 0 0 0-2-2h-5.3l.9-4.3A2 2 0 0 0 13.6 1L8 8v13h10a2 2 0 0 0 2-1.6l2-8A2 2 0 0 0 22 10z" />
                </svg>
              </span>
              <span className="v3-mini-row" style={{ padding: "9px 14px", color: "var(--text-faint)" }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" aria-hidden>
                  <path d="M2 10h4v11H2zM22 10a2 2 0 0 0-2-2h-5.3l.9-4.3A2 2 0 0 0 13.6 1L8 8v13h10a2 2 0 0 0 2-1.6l2-8A2 2 0 0 0 22 10z" transform="rotate(180 12 12)" />
                </svg>
              </span>
            </div>
          </div>

          <div className="v3-bento-card">
            <h3 className="v3-bento-title">A quiet menu bar app</h3>
            <p className="v3-bento-copy">
              Cue Booth lives in the menu bar: live now-playing, transport,
              launch-at-login — and a pairing code masked by default, because
              that window ends up in screen shares.
            </p>
            <div className="v3-bento-vignette">
              <div className="v3-mini-row" style={{ justifyContent: "space-between" }}>
                <span style={{ fontSize: 12.5, fontWeight: 600, color: "var(--text-strong)" }}>Pairing code</span>
                <span className="v3-mono" style={{ fontSize: 13, letterSpacing: "0.2em", color: "var(--text-muted)" }}>••••••</span>
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* ============ Privacy manifesto ============ */

export function Privacy() {
  return (
    <div className="v3-panel-band">
      <div className="v3-panel" style={{ background: "var(--tint-lavender)" }}>
        <div className="v3-orb" style={{ width: 720, height: 520, left: "50%", top: -180, transform: "translateX(-50%)", opacity: 0.45 }} />
        <div className="v3-panel-pad">
          <Reveal className="v3-manifesto">
            <span className="v3-eyebrow">Local-only, by construction</span>
            <h2 className="v3-display" style={{ fontSize: "clamp(34px, 4.8vw, 54px)", lineHeight: 1.08 }}>
              No cloud. No account.
              <br />
              No server to trust.
            </h2>
            <p className="v3-lead" style={{ maxWidth: 620 }}>
              Cue is two apps on your own two machines. They find each other with
              Bonjour, speak over a WebSocket on your Wi-Fi, and prove themselves
              with a six-digit code — once. Nothing leaves the house, because
              there is nowhere for it to go.
            </p>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap", justifyContent: "center" }}>
              <span className="v3-chip">Bonjour discovery</span>
              <span className="v3-chip">Paired with a code, once</span>
              <span className="v3-chip">A wire protocol you can read</span>
              <span className="v3-chip">MIT licensed</span>
            </div>
          </Reveal>
        </div>
      </div>
    </div>
  );
}

/* ============ How it works ============ */

export function HowItWorks() {
  return (
    <section className="v3-section">
      <div className="v3-wrap" style={{ display: "flex", flexDirection: "column", gap: 40 }}>
        <Reveal>
          <div style={{ maxWidth: 520, display: "flex", flexDirection: "column", gap: 16 }}>
            <span className="v3-eyebrow">Setup</span>
            <h2 className="v3-display v3-h2">Three steps. The last one is a formality.</h2>
          </div>
        </Reveal>
        <Reveal stagger={110} className="v3-steps">
          {[
            {
              n: "01",
              t: "Run Cue Booth on your Mac",
              c: "It sits in the menu bar, watches what's playing, and shows a pairing code.",
            },
            {
              n: "02",
              t: "Open Cue on your iPhone",
              c: "It finds your Mac on its own. One Mac on the network, and it connects by itself.",
            },
            {
              n: "03",
              t: "Enter the code. Once.",
              c: "That's the setup. Add the Chrome extension for real titles, posters, queues and fullscreen.",
            },
          ].map((s) => (
            <div key={s.n} className="v3-step-card" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              <span className="v3-mono" style={{ fontSize: 13, fontWeight: 600, color: "var(--sun-magenta)" }}>{s.n}</span>
              <span style={{ fontFamily: "var(--font-display)", fontSize: 20, fontWeight: 620, color: "var(--text-strong)", letterSpacing: "-0.01em" }}>
                {s.t}
              </span>
              <span style={{ fontSize: 14.5, lineHeight: 1.55, color: "var(--text-body)" }}>{s.c}</span>
            </div>
          ))}
        </Reveal>
        <Reveal>
          <p style={{ margin: 0, fontSize: 13.5, color: "var(--text-muted)" }}>
            Needs macOS 14+, iOS 17+, and both machines on the same Wi-Fi.
            Browser control is Chrome, via the bundled extension. Wear an Apple
            Watch? The watch app rides along automatically — it talks through
            your iPhone.
          </p>
        </Reveal>
      </div>
    </section>
  );
}

/* ============ Receipts ============ */

export function Receipts() {
  return (
    <section className="v3-section v3-receipts" id="details">
      <div className="v3-wrap" style={{ display: "flex", flexDirection: "column", gap: 40 }}>
        <Reveal>
          <div style={{ maxWidth: 560, display: "flex", flexDirection: "column", gap: 16 }}>
            <span className="v3-eyebrow">For the skeptical</span>
            <h2 className="v3-display v3-h2">Details that survived measurement.</h2>
            <p className="v3-lead">
              Most of Cue is invisible plumbing. These are the numbers it is
              built around.
            </p>
          </div>
        </Reveal>
        <Reveal stagger={70} className="v3-receipt-grid">
          {[
            ["84 s", "how far a “+15s” skip actually moved Netflix when trusting macOS's drifting position. Cue reads the video's own clock instead."],
            ["120 ms", "the state-broadcast throttle. Full snapshots every time, never diffs — the phone cannot drift out of sync."],
            ["≤3 KB", "the artwork squeezed into a Live Activity's ~4 KB payload budget, compressed adaptively until it fits."],
            ["10%", "how far into a file QuickTime thumbnails are taken, so a fade-from-black never yields a black frame."],
            ["180 pt", "the artwork relayed to the watch — more than a 45 mm screen resolves, small enough for the payload budget."],
            ["6.25%", "how much one press of the iPhone's volume buttons nudges the Mac — the phone re-centers itself so presses never stop registering."],
            ["1 key", "the trusted f keystroke that fullscreens YouTube, Netflix, Prime and Hotstar alike."],
            ["0", "accounts, servers, analytics, and cloud round-trips per tap."],
          ].map(([n, c]) => (
            <div key={n as string} className="v3-receipt">
              <span className="v3-receipt-num">{n}</span>
              <p>{c}</p>
            </div>
          ))}
        </Reveal>
      </div>
    </section>
  );
}

/* ============ Get Cue ============ */

export function GetCue() {
  return (
    <section className="v3-section" id="get-cue" style={{ paddingTop: 48 }}>
      <div className="v3-wrap" style={{ display: "flex", flexDirection: "column", gap: 40 }}>
        <Reveal>
          <div style={{ maxWidth: 520, display: "flex", flexDirection: "column", gap: 16 }}>
            <span className="v3-eyebrow">Get Cue</span>
            <h2 className="v3-display v3-h2">Two ways to get it.</h2>
          </div>
        </Reveal>
        <Reveal stagger={120} className="v3-get-grid">
          <div className="v3-get-card" style={{ background: "var(--surface-card)", border: "1px solid var(--border-subtle)", boxShadow: "var(--shadow-sm)" }}>
            <span style={{ fontSize: 12.5, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-muted)" }}>
              Build it yourself
            </span>
            <span className="v3-price-tag">Free</span>
            <p style={{ margin: 0, fontSize: 15, lineHeight: 1.6, color: "var(--text-body)" }}>
              Clone the repo, run one script for the Mac app, build the iPhone
              app in Xcode. About five minutes, MIT licensed, and a free Apple
              ID is enough.
            </p>
            <ul className="v3-check-list" style={{ marginTop: 4 }}>
              <li><Check />The whole source, forever</li>
              <li><Check />No Apple developer account needed</li>
              <li><Check />Fixes and features land in the open</li>
            </ul>
            <a className="v3-btn v3-btn-primary" style={{ marginTop: "auto", width: "fit-content" }} href={GITHUB} target="_blank" rel="noreferrer">
              Get it on GitHub
            </a>
          </div>
          <div className="v3-get-card" style={{ background: "var(--grad-brand-soft)", boxShadow: "var(--ring-hairline)" }}>
            <span style={{ fontSize: 12.5, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--sun-magenta)" }}>
              Buy Cue
            </span>
            <span className="v3-price-tag">Coming soon</span>
            <p style={{ margin: 0, fontSize: 15, lineHeight: 1.6, color: "var(--text-body)" }}>
              A signed, ready-made build of both apps — no Xcode, no seven-day
              re-signs, updates included. One-time purchase; the price is still
              settling.
            </p>
            <ul className="v3-check-list" style={{ marginTop: 4 }}>
              <li><Check />Install and go — no build step</li>
              <li><Check />Properly signed and notarized</li>
              <li><Check />Same app, same local-only promise</li>
            </ul>
            <a className="v3-btn v3-btn-ghost" style={{ marginTop: "auto", width: "fit-content" }} href={GITHUB} target="_blank" rel="noreferrer">
              Watch the repo for the release
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* ============ FAQ ============ */

export function FaqSection() {
  return (
    <section className="v3-section" id="faq" style={{ paddingTop: 32 }}>
      <div className="v3-wrap" style={{ display: "flex", flexDirection: "column", gap: 40 }}>
        <Reveal>
          <div style={{ textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
            <span className="v3-eyebrow">Straight answers</span>
            <h2 className="v3-display v3-h2">Questions, answered.</h2>
          </div>
        </Reveal>
        <Reveal>
          <Faq />
        </Reveal>
      </div>
    </section>
  );
}

/* ============ Footer ============ */

export function Footer() {
  return (
    <footer className="v3-footer">
      <div style={{ padding: "110px 24px 150px", position: "relative", zIndex: 1 }}>
        <Reveal className="v3-manifesto" >
          <h2 className="v3-display" style={{ fontSize: "clamp(38px, 5.4vw, 62px)", lineHeight: 1.05 }}>
            Press play from anywhere.
          </h2>
          <p className="v3-lead" style={{ maxWidth: 480 }}>
            Well — anywhere on your Wi-Fi.
          </p>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap", justifyContent: "center" }}>
            <a className="v3-btn v3-btn-primary" href={GITHUB} target="_blank" rel="noreferrer">
              Get it on GitHub
            </a>
            <a className="v3-btn v3-btn-ghost" href={`${GITHUB}#readme`} target="_blank" rel="noreferrer">
              Read the README
            </a>
          </div>
        </Reveal>
      </div>
      <div
        style={{
          position: "relative",
          zIndex: 1,
          borderTop: "1px solid var(--border-subtle)",
          padding: "22px 24px",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 18,
          fontSize: 13,
          color: "var(--text-muted)",
          flexWrap: "wrap",
        }}
      >
        <span style={{ display: "flex", alignItems: "center", gap: 8 }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img className="v3-logo-light" src="/logo.png" alt="" width={18} height={18} style={{ borderRadius: 5 }} />
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img className="v3-logo-dark" src="/logo-dark.png" alt="" width={18} height={18} style={{ borderRadius: 5 }} />
          Cue
        </span>
        <span>·</span>
        <span>Made by Niket Singh</span>
        <span>·</span>
        <a href={`${GITHUB}/blob/main/LICENSE`} target="_blank" rel="noreferrer" style={{ color: "inherit" }}>
          MIT License
        </a>
        <span>·</span>
        <span>No cookies, no tracking — obviously</span>
      </div>
      <div className="v3-ghost-wordmark">Cue</div>
    </footer>
  );
}
