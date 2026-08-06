/* A DOM-built Apple Watch showing Cue's watch app. Like the phone mockup:
   real text, crisp at any scale, always the app's dark UI. Decorative only. */

export function CueWatch() {
  return (
    <div className="v3-watch" aria-hidden="true" {...{ inert: true }}>
      {/* crown + side button */}
      <div className="v3-watch-crown" />
      <div className="v3-watch-side" />

      <div className="v3-watch-screen">
        {/* artwork + title */}
        <div style={{ display: "flex", alignItems: "center", gap: 9 }}>
          <span
            style={{
              width: 40,
              height: 40,
              borderRadius: 9,
              flexShrink: 0,
              background: "linear-gradient(140deg, #f7941e, #d9327a 70%, #5b2bb8)",
            }}
          />
          <span style={{ minWidth: 0 }}>
            <span
              style={{
                display: "block",
                fontSize: 13.5,
                fontWeight: 600,
                color: "#f6f2ea",
                whiteSpace: "nowrap",
                overflow: "hidden",
                textOverflow: "ellipsis",
              }}
            >
              Midnight Reverie
            </span>
            <span style={{ display: "block", fontSize: 11, color: "rgba(242,237,228,0.55)" }}>
              The Sundowners
            </span>
          </span>
        </div>

        {/* progress — a bar, not timestamps */}
        <div
          style={{
            marginTop: 12,
            height: 3,
            borderRadius: 2,
            background: "rgba(242,237,228,0.16)",
            position: "relative",
          }}
        >
          <span
            style={{
              position: "absolute",
              inset: "0 auto 0 0",
              width: "34%",
              borderRadius: 2,
              background: "linear-gradient(90deg, #f7941e, #e0447c)",
            }}
          />
        </div>

        {/* transport */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 13,
            marginTop: 13,
            color: "#f2ede4",
          }}
        >
          <span className="v3-watch-skip">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 5V2L7 6l5 4V7a6 6 0 1 1-6 6" />
            </svg>
          </span>
          <span
            style={{
              width: 40,
              height: 40,
              borderRadius: 21,
              background: "rgba(242,237,228,0.16)",
              display: "inline-flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="#f6f2ea">
              <rect x="6" y="4" width="4.5" height="16" rx="1.5" />
              <rect x="13.5" y="4" width="4.5" height="16" rx="1.5" />
            </svg>
          </span>
          <span className="v3-watch-skip">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 5V2l5 4-5 4V7a6 6 0 1 0 6 6" />
            </svg>
          </span>
        </div>

        {/* volume readout — the crown drives this */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 5,
            marginTop: 11,
            fontSize: 11,
            fontWeight: 500,
            color: "rgba(242,237,228,0.55)",
          }}
        >
          <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor">
            <path d="M4 9v6h4l5 4V5L8 9H4zm12.5 3a4.5 4.5 0 0 0-2.5-4v8a4.5 4.5 0 0 0 2.5-4z" />
          </svg>
          <span className="v3-mono">52%</span>
        </div>
      </div>
    </div>
  );
}
