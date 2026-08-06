"use client";

import { useState } from "react";

const ITEMS: { q: string; a: string }[] = [
  {
    q: "Does anything leave my network?",
    a: "No. Your phone talks to your Mac over a WebSocket on your own Wi-Fi, discovered with Bonjour and protected by a one-time pairing code. There is no server, no account, and no analytics. The one optional exception: if you add a free TMDB key, the Mac fetches show posters from TMDB — that's it.",
  },
  {
    q: "Which browsers work?",
    a: "Chrome, via the Cue Bridge extension — that's where the real titles, artwork, queue and fullscreen come from. Safari would need its own extension and isn't supported yet. VLC, QuickTime, Music and Spotify work without any browser at all.",
  },
  {
    q: "Why does fullscreen need an Accessibility permission?",
    a: "Browsers only allow video fullscreen from a real keypress — no extension or script can fake it. So Cue focuses the player and the Mac app presses the fullscreen key through the system's own input stack. macOS gates that behind a one-time Accessibility grant. Without it, Cue still fullscreens the browser window and tells you so.",
  },
  {
    q: "What do I need to run it?",
    a: "A Mac on macOS 14+, an iPhone on iOS 17+, and both on the same Wi-Fi. The Mac has to be awake. An Apple Watch is optional — the watch app relays through your iPhone, so it needs no setup of its own. Everything works on a free Apple ID — no push entitlements, no App Groups, no paid developer account required.",
  },
  {
    q: "Will an update break it?",
    a: "Honest answer: the now-playing feed rides a community adapter for an API Apple restricted in macOS 15.4 — it's the single most likely thing to break on a future macOS release. Everything else (the extension, VLC, QuickTime control) uses stable, documented interfaces. It's open source, so fixes land in the open.",
  },
  {
    q: "Is it really free?",
    a: "The source is MIT-licensed and always will be — clone it and build both apps yourself in about five minutes. A ready-made, signed build you can just install is coming as a one-time purchase, for people who'd rather not open Xcode.",
  },
];

export function Faq() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <div className="v3-faq">
      {ITEMS.map((item, i) => (
        <div key={i} className="v3-faq-item" data-open={open === i}>
          <button
            className="v3-faq-q"
            onClick={() => setOpen(open === i ? null : i)}
            aria-expanded={open === i}
          >
            {item.q}
            <svg
              className="v3-faq-chevron"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="m9 18 6-6-6-6" />
            </svg>
          </button>
          <div className="v3-faq-a" style={{ maxHeight: open === i ? 260 : 0 }}>
            <div>{item.a}</div>
          </div>
        </div>
      ))}
    </div>
  );
}
