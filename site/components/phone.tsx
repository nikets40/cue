/* A DOM-built iPhone showing Cue's player. Real text, crisp at any
   scale, always the app's stage-dark UI regardless of site theme.
   Decorative only — hidden from the a11y tree. */

const eqDelays = [0, 0.18, 0.09, 0.27, 0.05];

export function CuePhone() {
  return (
    <div className="v3-phone" aria-hidden="true" {...{ inert: true }}>
      <div className="v3-phone-screen">
        <div className="v3-phone-notch" />

        {/* status bar */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            padding: "16px 28px 0",
            fontSize: 13,
            fontWeight: 600,
            color: "rgba(242,237,228,0.9)",
          }}
        >
          <span>9:41</span>
          <span style={{ display: "flex", gap: 5, alignItems: "center" }}>
            <svg width="15" height="11" viewBox="0 0 16 12" fill="currentColor">
              <path d="M8 9.5a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3zM4.9 7.6l1.4 1.4a2.5 2.5 0 0 1 3.4 0l1.4-1.4a4.5 4.5 0 0 0-6.2 0zM2 4.7l1.4 1.4a6.5 6.5 0 0 1 9.2 0L14 4.7a8.5 8.5 0 0 0-12 0z" />
            </svg>
            <svg width="22" height="11" viewBox="0 0 25 12" fill="none">
              <rect x="0.5" y="0.5" width="21" height="11" rx="3" stroke="currentColor" opacity="0.5" />
              <rect x="2" y="2" width="15" height="8" rx="1.5" fill="currentColor" />
              <path d="M23.5 4v4a2 2 0 0 0 0-4z" fill="currentColor" opacity="0.5" />
            </svg>
          </span>
        </div>

        {/* connection header */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 7,
            marginTop: 14,
            fontSize: 12.5,
            fontWeight: 600,
            color: "rgba(242,237,228,0.62)",
          }}
        >
          <span
            className="v3-pulse-dot"
            style={{
              width: 7,
              height: 7,
              borderRadius: 4,
              background: "rgb(110,232,161)",
              animation: "v3-pulse 2.4s ease-in-out infinite",
            }}
          />
          MacBook Pro
        </div>

        {/* artwork — CSS-drawn album cover */}
        <div style={{ padding: "22px 26px 0" }}>
          <div
            style={{
              width: "100%",
              aspectRatio: "1",
              borderRadius: 18,
              position: "relative",
              overflow: "hidden",
              background:
                "linear-gradient(140deg, #f7941e 0%, #ef5f38 30%, #d9327a 62%, #5b2bb8 100%)",
              boxShadow: "0 18px 44px rgba(0,0,0,0.5)",
            }}
          >
            <div
              style={{
                position: "absolute",
                inset: 0,
                background:
                  "radial-gradient(58% 58% at 68% 30%, rgba(255,236,200,0.55), transparent 65%)",
              }}
            />
            <div
              style={{
                position: "absolute",
                left: "12%",
                bottom: "14%",
                width: "44%",
                aspectRatio: "1",
                borderRadius: "50%",
                border: "2.5px solid rgba(255,248,238,0.5)",
              }}
            />
            <div
              style={{
                position: "absolute",
                left: "26%",
                bottom: "28%",
                width: "16%",
                aspectRatio: "1",
                borderRadius: "50%",
                background: "rgba(20,12,26,0.55)",
              }}
            />
            {/* equalizer badge */}
            <div
              style={{
                position: "absolute",
                right: 12,
                bottom: 12,
                display: "flex",
                alignItems: "flex-end",
                gap: 3,
                height: 18,
                padding: "5px 8px",
                borderRadius: 9,
                background: "rgba(16,12,20,0.55)",
                backdropFilter: "blur(6px)",
              }}
            >
              {eqDelays.map((d, i) => (
                <span
                  key={i}
                  className="v3-eqbar"
                  style={{ height: 10, animationDelay: `${d}s` }}
                />
              ))}
            </div>
          </div>
        </div>

        {/* title block */}
        <div style={{ padding: "20px 28px 0" }}>
          <div
            style={{
              fontSize: 19,
              fontWeight: 700,
              letterSpacing: "-0.01em",
              color: "#f6f2ea",
            }}
          >
            Midnight Reverie
          </div>
          <div style={{ fontSize: 14, marginTop: 3, color: "rgba(242,237,228,0.55)" }}>
            The Sundowners · YouTube Music
          </div>
        </div>

        {/* scrubber */}
        <div style={{ padding: "18px 28px 0" }}>
          <div
            style={{
              height: 5,
              borderRadius: 3,
              background: "rgba(242,237,228,0.16)",
              position: "relative",
            }}
          >
            <div
              style={{
                position: "absolute",
                inset: "0 auto 0 0",
                width: "34%",
                borderRadius: 3,
                background: "linear-gradient(90deg, #f7941e, #e0447c)",
              }}
            />
            <div
              style={{
                position: "absolute",
                left: "34%",
                top: "50%",
                transform: "translate(-50%,-50%)",
                width: 11,
                height: 11,
                borderRadius: 6,
                background: "#f6f2ea",
                boxShadow: "0 1px 4px rgba(0,0,0,0.4)",
              }}
            />
          </div>
          <div
            className="v3-mono"
            style={{
              display: "flex",
              justifyContent: "space-between",
              marginTop: 7,
              fontSize: 11.5,
              color: "rgba(242,237,228,0.45)",
            }}
          >
            <span>1:14</span>
            <span>−2:22</span>
          </div>
        </div>

        {/* transport */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 26,
            marginTop: 16,
            color: "#f2ede4",
          }}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" opacity="0.85">
            <path d="M6 6h2v12H6zM20 6v12L9.5 12z" />
          </svg>
          <div
            style={{
              width: 66,
              height: 66,
              borderRadius: 34,
              background: "#f6f2ea",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              boxShadow: "0 8px 24px rgba(0,0,0,0.4)",
            }}
          >
            {/* pause glyph — it's playing */}
            <svg width="22" height="22" viewBox="0 0 24 24" fill="#16130f">
              <rect x="6" y="4" width="4.5" height="16" rx="1.5" />
              <rect x="13.5" y="4" width="4.5" height="16" rx="1.5" />
            </svg>
          </div>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" opacity="0.85">
            <path d="M6 6h2v12H6zM20 6v12L9.5 12z" transform="rotate(180 12 12)" />
          </svg>
        </div>

        {/* volume */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 12,
            padding: "22px 30px 0",
            color: "rgba(242,237,228,0.5)",
          }}
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
            <path d="M4 9v6h4l5 4V5L8 9H4z" />
          </svg>
          <div
            style={{
              flex: 1,
              height: 4,
              borderRadius: 2,
              background: "rgba(242,237,228,0.16)",
              position: "relative",
            }}
          >
            <div
              style={{
                position: "absolute",
                inset: "0 auto 0 0",
                width: "52%",
                borderRadius: 2,
                background: "rgba(242,237,228,0.75)",
              }}
            />
          </div>
          <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor">
            <path d="M4 9v6h4l5 4V5L8 9H4zm12.5 3a4.5 4.5 0 0 0-2.5-4v8a4.5 4.5 0 0 0 2.5-4zM14 3.8v2.1a6.5 6.5 0 0 1 0 12.2v2.1a8.5 8.5 0 0 0 0-16.4z" />
          </svg>
        </div>

        {/* bottom actions */}
        <div
          style={{
            marginTop: "auto",
            display: "flex",
            justifyContent: "center",
            gap: 14,
            padding: "0 28px 26px",
          }}
        >
          {[
            // sources
            <svg key="s" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round">
              <rect x="3" y="4" width="18" height="12" rx="2" />
              <path d="M8 20h8" />
            </svg>,
            // queue
            <svg key="q" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round">
              <path d="M4 6h12M4 12h12M4 18h7" />
              <path d="M19 14v6m0 0 2.5-2M19 20l-2.5-2" strokeWidth="1.7" />
            </svg>,
            // fullscreen
            <svg key="f" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round">
              <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3" />
            </svg>,
          ].map((icon, i) => (
            <div
              key={i}
              style={{
                width: 46,
                height: 46,
                borderRadius: 24,
                background: "rgba(242,237,228,0.08)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "rgba(242,237,228,0.8)",
              }}
            >
              {icon}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
