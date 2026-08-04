/**
 * The C-Play mark, redrawn as SVG from tools/make-icon.swift
 * (same geometry: 1024 canvas, ring r=230 stroke=118 gap ±38°,
 * play triangle with rounded corners, optically centered at x=522).
 */
export function CueMark({
  className,
  ink = "#fff",
}: {
  className?: string;
  ink?: string;
}) {
  return (
    <svg viewBox="0 0 1024 1024" className={className} aria-hidden="true">
      <path
        d="M 703.2 370.4 A 230 230 0 1 0 703.2 653.6"
        fill="none"
        stroke={ink}
        strokeWidth="118"
        strokeLinecap="round"
      />
      <path
        d="M 451 400 L 451 624 L 660 512 Z"
        fill={ink}
        stroke={ink}
        strokeWidth="48"
        strokeLinejoin="round"
      />
    </svg>
  );
}

/** Mark on the sunset wash, matching the app icon. */
export function CueBadge({ className }: { className?: string }) {
  return (
    <span
      className={`inline-flex items-center justify-center overflow-hidden ${className ?? ""}`}
      style={{
        background:
          "radial-gradient(150% 150% at 12% 6%, #ff9d6c 0%, #d4507a 34%, #5b2a86 70%, #241a4a 100%)",
      }}
    >
      <CueMark className="w-[58%] h-[58%]" />
    </span>
  );
}
