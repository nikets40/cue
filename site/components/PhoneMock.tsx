import { CueMark } from "./Logo";

/* Small transport glyphs, drawn to match the app's plain white controls. */
function PlayIcon() {
  return (
    <svg viewBox="0 0 24 24" className="w-7 h-7" fill="currentColor" aria-hidden="true">
      <path d="M8 5.5c0-1.1 1.2-1.8 2.2-1.2l9.2 6.5c.9.6.9 1.9 0 2.5l-9.2 6.5c-1 .6-2.2-.1-2.2-1.2V5.5Z" />
    </svg>
  );
}

function SkipIcon({ back = false }: { back?: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={`w-5 h-5 ${back ? "-scale-x-100" : ""}`}
      fill="currentColor"
      aria-hidden="true"
    >
      <path d="M4 6.3c0-1 1.1-1.6 2-1.1l7 4.6v-4c0-.7.6-1.3 1.3-1.3.7 0 1.2.6 1.2 1.3v12.4c0 .7-.5 1.3-1.2 1.3-.7 0-1.3-.6-1.3-1.3v-4l-7 4.6c-.9.5-2-.1-2-1.1V6.3Z" />
    </svg>
  );
}

function SpeakerIcon({ loud = false }: { loud?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" className="w-3.5 h-3.5" fill="currentColor" aria-hidden="true">
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
 * The Cue player, direction A "Backdrop": blurred artwork wash + scrim
 * + white glass controls over a stage-dark chassis. Mirrors RemoteView.swift.
 */
export function PhoneMock() {
  return (
    <div
      className="relative w-[290px] sm:w-[320px] rounded-[52px] border border-white/15 bg-black p-[10px] shadow-[0_40px_120px_-30px_rgb(212_80_122/0.35),0_30px_60px_-30px_rgb(0_0_0/0.8)]"
      role="img"
      aria-label="The Cue iPhone app playing a track, with artwork, scrubber, transport controls and a volume slider"
    >
      <div className="relative overflow-hidden rounded-[42px] bg-stage-2 aspect-[9/19.2]">
        {/* Backdrop: blurred sunset wash, like blown-up album art */}
        <div
          className="absolute -inset-8 scale-125 blur-2xl saturate-150"
          style={{
            background:
              "radial-gradient(120% 90% at 18% 8%, #ff9d6c 0%, #d4507a 36%, #5b2a86 68%, #241a4a 100%)",
          }}
        />
        {/* Scrim so the white controls always read */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/25 via-black/35 to-black/60" />

        <div className="relative flex h-full flex-col px-5 pb-6 pt-3 text-white">
          {/* Dynamic Island, playing state */}
          <div className="mx-auto flex h-[26px] w-[108px] items-center justify-between rounded-full bg-black px-2.5">
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

          <div className="flex-1" />

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
          <div className="mt-5 text-center">
            <div className="text-[15px] font-bold">Midnight City</div>
            <div className="mt-0.5 text-[12px] text-white/70">
              M83 · Hurry Up, We&apos;re Dreaming
            </div>
          </div>

          {/* Scrubber */}
          <div className="mt-5">
            <div className="h-[4px] overflow-hidden rounded-full bg-white/25">
              <div className="progress-tick h-full rounded-full bg-white/90" />
            </div>
            <div className="mt-1.5 flex justify-between text-[9.5px] tabular-nums text-white/60">
              <span>1:47</span>
              <span>4:03</span>
            </div>
          </div>

          {/* Transport */}
          <div className="mt-4 flex items-center justify-center gap-7">
            <SkipIcon back />
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-white text-stage-2 shadow-[0_8px_24px_-6px_rgb(0_0_0/0.5)]">
              <PlayIcon />
            </div>
            <SkipIcon />
          </div>

          {/* Volume */}
          <div className="mt-6 flex items-center gap-2.5 text-white/60">
            <SpeakerIcon />
            <div className="h-[4px] flex-1 rounded-full bg-white/25">
              <div className="h-full w-[58%] rounded-full bg-white/80" />
            </div>
            <SpeakerIcon loud />
          </div>
        </div>
      </div>
    </div>
  );
}
