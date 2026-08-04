import { CueMark } from "./Logo";

/* ---------------------------------------------------------------- */
/* Step graphics for "How it works" — concrete mini-mockups, not     */
/* abstract clip art. Same chassis: dark inset, hairline border.     */
/* ---------------------------------------------------------------- */

function ArtBlock({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div
      className={`relative mb-6 h-[136px] overflow-hidden rounded-2xl border border-white/[0.07] bg-black/25 ${className ?? ""}`}
      aria-hidden="true"
    >
      {children}
    </div>
  );
}

/* Step 1: the Mac menu bar with Booth living in it. */
export function MenuBarArt() {
  return (
    <ArtBlock>
      <div className="flex h-8 items-center justify-between border-b border-white/[0.06] bg-white/[0.05] px-3 text-[10.5px] text-white/45">
        <div className="flex items-center gap-3">
          <span className="font-bold text-white/70">Finder</span>
          <span>File</span>
          <span>Edit</span>
          <span>View</span>
        </div>
        <div className="flex items-center gap-2.5">
          <span className="flex h-5 w-5 items-center justify-center rounded-md bg-white/[0.09]">
            <CueMark className="h-3 w-3" />
          </span>
          {/* wifi */}
          <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <path d="M2.5 9.5a14 14 0 0 1 19 0" />
            <path d="M6 13a9 9 0 0 1 12 0" />
            <path d="M9.5 16.5a4.5 4.5 0 0 1 5 0" />
            <circle cx="12" cy="19.5" r="1.2" fill="currentColor" stroke="none" />
          </svg>
          <span>14:32</span>
        </div>
      </div>
      <div className="p-3">
        <div className="rounded-xl border border-white/[0.08] bg-white/[0.05] p-3">
          <div className="flex items-center gap-1.5 text-[10.5px] font-semibold text-white/75">
            <span className="h-[5px] w-[5px] rounded-full bg-go" />
            Serving on port 41952
          </div>
          <div className="mt-1.5 flex items-center gap-2 text-[10.5px] text-white/50">
            <span
              className="h-6 w-6 shrink-0 rounded-[6px]"
              style={{
                background:
                  "radial-gradient(140% 140% at 20% 10%, #ff9d6c 0%, #d4507a 45%, #5b2a86 100%)",
              }}
            />
            <span className="truncate">Midnight City — M83 · playing in Chrome</span>
          </div>
        </div>
      </div>
    </ArtBlock>
  );
}

/* Step 2: Bonjour discovery — ripples radiating from a found Mac. */
export function DiscoveryArt() {
  return (
    <ArtBlock className="flex flex-col items-center justify-center gap-3">
      <span className="ripple absolute h-40 w-40 rounded-full border border-rose/40" />
      <span className="ripple ripple-2 absolute h-40 w-40 rounded-full border border-peach/40" />
      <div className="relative flex items-center gap-2.5 rounded-full border border-white/[0.1] bg-white/[0.06] py-2 pl-4 pr-2">
        <span className="h-[6px] w-[6px] rounded-full bg-go" />
        <span className="text-[12px] font-semibold text-white/85">MacBook Pro</span>
        <span className="rounded-full bg-white/90 px-3 py-1 text-[10.5px] font-bold text-stage">
          Connect
        </span>
      </div>
      <div className="relative text-[9.5px] font-semibold uppercase tracking-[0.28em] text-white/40">
        Pairing code&ensp;4 8 2 9 1 3
      </div>
    </ArtBlock>
  );
}

/* Step 3: the wire — tiny JSON commands one way, snapshots back. */
export function WireArt() {
  return (
    <ArtBlock className="flex flex-col justify-center gap-2.5 px-4">
      <svg
        className="absolute inset-x-6 top-1/2 h-px w-auto -translate-y-1/2 text-white/25"
        preserveAspectRatio="none"
        viewBox="0 0 100 2"
      >
        <line
          x1="0"
          y1="1"
          x2="100"
          y2="1"
          stroke="currentColor"
          strokeWidth="2"
          strokeDasharray="4 4"
          className="dash-flow"
        />
      </svg>
      <div className="relative flex justify-end">
        <span className="rounded-lg border border-white/[0.1] bg-stage-2 px-2.5 py-1.5 font-mono text-[10px] text-peach">
          {'{"action":"play"}'}&ensp;→
        </span>
      </div>
      <div className="relative flex justify-start">
        <span className="rounded-lg border border-white/[0.1] bg-stage-2 px-2.5 py-1.5 font-mono text-[10px] text-ink-2">
          ←&ensp;{'{"title":"Midnight City","playing":true}'}
        </span>
      </div>
    </ArtBlock>
  );
}

/* ---------------------------------------------------------------- */
/* Feature icons — stroke glyphs on a faint sunset tile.             */
/* ---------------------------------------------------------------- */

export function FeatureTile({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="mb-5 flex h-11 w-11 items-center justify-center rounded-xl border border-white/[0.1] text-white/90"
      style={{
        background:
          "linear-gradient(135deg, rgb(255 157 108 / 0.22), rgb(212 80 122 / 0.2) 45%, rgb(91 42 134 / 0.28))",
      }}
      aria-hidden="true"
    >
      {children}
    </div>
  );
}

const glyph = {
  className: "h-[22px] w-[22px]",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.8,
  strokeLinecap: "round",
  strokeLinejoin: "round",
} as const;

export function IconVolume() {
  return (
    <svg viewBox="0 0 24 24" {...glyph}>
      <path d="M4.5 9.5h2.4L11 6.3v11.4l-4.1-3.2H4.5a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1Z" fill="currentColor" stroke="none" />
      <path d="M14.4 9.2a4.1 4.1 0 0 1 0 5.6" />
      <path d="M17 6.5a8 8 0 0 1 0 11" />
    </svg>
  );
}

export function IconIsland() {
  return (
    <svg viewBox="0 0 24 24" {...glyph}>
      <rect x="3" y="8.4" width="18" height="7.2" rx="3.6" />
      <circle cx="7.6" cy="12" r="1.3" fill="currentColor" stroke="none" />
      <path d="M13.6 10.9v2.2M15.9 10v4M18.2 10.9v2.2" strokeWidth="1.6" />
    </svg>
  );
}

export function IconArtwork() {
  return (
    <svg viewBox="0 0 24 24" {...glyph}>
      <rect x="4" y="4" width="16" height="16" rx="3" />
      <circle cx="9.1" cy="9.1" r="1.5" fill="currentColor" stroke="none" />
      <path d="M4.8 16.8l3.8-3.8 3.1 3.1 3.2-3.2 4.3 4.3" />
    </svg>
  );
}

export function IconLock() {
  return (
    <svg viewBox="0 0 24 24" {...glyph}>
      <rect x="5.5" y="10.5" width="13" height="9" rx="2.5" />
      <path d="M8.5 10.5V8.2a3.5 3.5 0 0 1 7 0v2.3" />
      <circle cx="12" cy="15" r="1.4" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function IconReconnect() {
  return (
    <svg viewBox="0 0 24 24" {...glyph}>
      <path d="M18.4 8.5A7 7 0 0 0 5.8 9.7" />
      <path d="M18.9 4.6v3.9H15" />
      <path d="M5.6 15.5a7 7 0 0 0 12.6-1.2" />
      <path d="M5.1 19.4v-3.9H9" />
    </svg>
  );
}

export function IconSkip15() {
  return (
    <svg viewBox="0 0 24 24" {...glyph}>
      <path d="M7.4 5.5A8 8 0 1 1 4.6 11" />
      <path d="M7.8 2.4v3.5H4.3" />
      <text
        x="12.2"
        y="15.4"
        textAnchor="middle"
        fontSize="8"
        fontWeight="800"
        fill="currentColor"
        stroke="none"
      >
        15
      </text>
    </svg>
  );
}

/* ---------------------------------------------------------------- */
/* Fine-print icons — small, muted.                                  */
/* ---------------------------------------------------------------- */

export function FaqTile({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="mb-4 flex h-9 w-9 items-center justify-center rounded-lg border border-white/[0.08] bg-white/[0.05] text-ink-2"
      aria-hidden="true"
    >
      {children}
    </div>
  );
}

const faqGlyph = { ...glyph, className: "h-[18px] w-[18px]" } as const;

export function IconTerminal() {
  return (
    <svg viewBox="0 0 24 24" {...faqGlyph}>
      <rect x="3.5" y="5" width="17" height="14" rx="2.5" />
      <path d="M7.2 10l2.6 2.2-2.6 2.2" />
      <path d="M12.4 14.6h4.4" />
    </svg>
  );
}

export function IconWifiHome() {
  return (
    <svg viewBox="0 0 24 24" {...faqGlyph}>
      <path d="M2.5 9.5a14 14 0 0 1 19 0" />
      <path d="M6 13a9 9 0 0 1 12 0" />
      <path d="M9.5 16.5a4.5 4.5 0 0 1 5 0" />
      <circle cx="12" cy="19.5" r="1.2" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function IconNoStore() {
  return (
    <svg viewBox="0 0 24 24" {...faqGlyph}>
      <path d="M6.5 8.5h11l1 11h-13l1-11Z" />
      <path d="M9 8.5V7a3 3 0 0 1 6 0v1.5" />
      <path d="M10 12.5l4 4M14 12.5l-4 4" />
    </svg>
  );
}

export function IconBolt() {
  return (
    <svg viewBox="0 0 24 24" {...faqGlyph}>
      <path d="M13 3 5.5 13.5H11L10 21l7.5-10.5H12L13 3Z" />
    </svg>
  );
}
