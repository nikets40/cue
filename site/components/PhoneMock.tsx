import { CueMark } from "./Logo";

/* Small transport glyphs, drawn to match the app's plain white controls. */
function PlayIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="w-7 h-7 translate-x-[2px]"
      fill="currentColor"
      aria-hidden="true"
    >
      <path d="M8 5.5c0-1.1 1.2-1.8 2.2-1.2l9.2 6.5c.9.6.9 1.9 0 2.5l-9.2 6.5c-1 .6-2.2-.1-2.2-1.2V5.5Z" />
    </svg>
  );
}

/* backward.fill / forward.fill style: two triangles, like the app. */
function SkipIcon({ back = false }: { back?: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={`w-[22px] h-[22px] ${back ? "-scale-x-100" : ""}`}
      fill="currentColor"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M3.4 7.4 L3.4 16.6 L10.6 12 Z" />
      <path d="M13 7.4 L13 16.6 L20.2 12 Z" />
    </svg>
  );
}

function SpeakerIcon({ loud = false }: { loud?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" className="w-4 h-4" fill="currentColor" aria-hidden="true">
      <path d="M4 9.5h2.8L11 6v12l-4.2-3.5H4a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1Z" />
      {loud && (
        <>
          <path d="M14.5 8.6a4.6 4.6 0 0 1 0 6.8" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
          <path d="M17 6a8 8 0 0 1 0 12" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        </>
      )}
    </svg>
  );
}

/**
 * The Cue player, direction A "Backdrop": sunset artwork wash + scrim
 * + white glass controls. Mirrors RemoteView.swift's portrait rhythm:
 * one centered stack, even gaps, controls never pinned to the bottom edge.
 */
export function PhoneMock() {
  return (
    <div
      className="relative w-[290px] sm:w-[320px] rounded-[52px] border border-white/15 bg-black p-[10px] shadow-[0_40px_120px_-30px_rgb(212_80_122/0.35),0_30px_60px_-30px_rgb(0_0_0/0.8)]"
      role="img"
      aria-label="The Cue iPhone app playing a track, with artwork, scrubber, transport controls and a volume slider"
    >
      <div
        className="relative overflow-hidden rounded-[42px] aspect-[9/19.2]"
        style={{
          background:
            "radial-gradient(130% 84% at 20% 0%, #ff9d6c 0%, #d4507a 34%, #5b2a86 66%, #241a4a 100%)",
        }}
      >
        {/* Scrim so the white controls always read */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/25 via-black/30 to-black/50" />

        <div className="relative flex h-full flex-col px-6 pb-5 pt-3 text-white">
          {/* Dynamic Island, playing state */}
          <div className="mx-auto flex h-[26px] w-[108px] shrink-0 items-center justify-between rounded-full bg-black px-2.5">
            <div className="h-3.5 w-3.5 rounded-[5px] bg-gradient-to-br from-peach to-violet" />
            <div className="eq flex h-3 items-end gap-[2.5px] text-go">
              <span className="h-3" />
              <span className="h-3" />
              <span className="h-3" />
              <span className="h-3" />
            </div>
          </div>

          {/* Connection header */}
          <div className="mt-4 flex items-center justify-between text-[11px] font-medium text-white/75">
            <span className="flex items-center gap-1.5">
              <span className="h-[6px] w-[6px] rounded-full bg-go" />
              MacBook Pro
            </span>
            <span>Disconnect</span>
          </div>

          <div className="flex-[2]" />

          {/* Cover */}
          <div
            className="mx-auto flex aspect-square w-[72%] items-center justify-center rounded-2xl shadow-[0_18px_40px_-12px_rgb(0_0_0/0.6)]"
            style={{
              background:
                "radial-gradient(140% 140% at 20% 10%, #ff9d6c 0%, #d4507a 40%, #5b2a86 78%, #241a4a 100%)",
            }}
          >
            <CueMark className="h-[38%] w-[38%] opacity-90" />
          </div>

          {/* Track info */}
          <div className="mt-6 text-center">
            <div className="text-[15px] font-bold">Midnight City</div>
            <div className="mt-0.5 text-[12px] text-white/70">
              M83 · Hurry Up, We&apos;re Dreaming
            </div>
          </div>

          {/* Scrubber */}
          <div className="mt-6">
            <div className="h-[4px] overflow-hidden rounded-full bg-white/25">
              <div className="progress-tick h-full rounded-full bg-white/90" />
            </div>
            <div className="mt-1.5 flex justify-between text-[10px] tabular-nums text-white/60">
              <span>1:47</span>
              <span>4:03</span>
            </div>
          </div>

          {/* Transport */}
          <div className="mt-5 flex items-center justify-center gap-8">
            <SkipIcon back />
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-white text-stage-2 shadow-[0_8px_24px_-6px_rgb(0_0_0/0.5)]">
              <PlayIcon />
            </div>
            <SkipIcon />
          </div>

          {/* Volume */}
          <div className="mt-7 flex items-center gap-3 text-white/60">
            <SpeakerIcon />
            <div className="h-[4px] flex-1 rounded-full bg-white/25">
              <div className="h-full w-[58%] rounded-full bg-white/80" />
            </div>
            <SpeakerIcon loud />
          </div>

          <div className="flex-[1]" />
        </div>
      </div>
    </div>
  );
}
