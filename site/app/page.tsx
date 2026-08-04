import { CueBadge, CueMark } from "@/components/Logo";
import { PhoneMock } from "@/components/PhoneMock";
import { Reveal } from "@/components/Reveal";

const GITHUB = "https://github.com/nikets40/cue";

function GitHubIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 16 16" className={className} fill="currentColor" aria-hidden="true">
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z" />
    </svg>
  );
}

/* ---------- Nav ---------- */

function Nav() {
  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-white/[0.06] bg-stage/70 backdrop-blur-xl">
      <nav className="mx-auto flex h-16 max-w-6xl items-center justify-between px-5 sm:px-8">
        <a href="#" className="flex items-center gap-2.5">
          <CueBadge className="h-8 w-8 rounded-[9px]" />
          <span className="text-[17px] font-extrabold tracking-tight">Cue</span>
        </a>
        <div className="hidden items-center gap-8 text-[14px] font-medium text-ink-2 sm:flex">
          <a href="#how" className="transition-colors hover:text-ink">
            How it works
          </a>
          <a href="#features" className="transition-colors hover:text-ink">
            Features
          </a>
          <a href="#install" className="transition-colors hover:text-ink">
            Install
          </a>
          <a href="#faq" className="transition-colors hover:text-ink">
            Fine print
          </a>
        </div>
        <a
          href={GITHUB}
          className="flex items-center gap-2 rounded-full border border-white/15 px-4 py-1.5 text-[13.5px] font-semibold transition-colors hover:border-white/30 hover:bg-white/5"
        >
          <GitHubIcon className="h-4 w-4" />
          GitHub
        </a>
      </nav>
    </header>
  );
}

/* ---------- Hero ---------- */

function Hero() {
  return (
    <section className="relative overflow-hidden pt-32 sm:pt-40">
      {/* Sunset glow, drifting slowly */}
      <div
        className="glow pointer-events-none absolute -top-[420px] left-1/2 h-[900px] w-[1300px] -translate-x-1/2 opacity-[0.32]"
        style={{
          background:
            "radial-gradient(closest-side, #ff9d6c 0%, #d4507a 34%, #5b2a86 62%, transparent 78%)",
        }}
      />
      <div className="relative mx-auto grid max-w-6xl items-center gap-16 px-5 sm:px-8 lg:grid-cols-[1.1fr_auto] lg:gap-8">
        <div className="max-w-xl">
          <Reveal>
            <p className="inline-flex items-center gap-2 rounded-full border border-white/12 bg-white/[0.04] px-3.5 py-1.5 text-[12.5px] font-semibold text-ink-2">
              <span className="h-1.5 w-1.5 rounded-full bg-go" />
              Open source · MIT · Swift, all the way down
            </p>
          </Reveal>
          <Reveal delay={80}>
            <h1 className="mt-6 text-[42px] font-extrabold leading-[1.04] tracking-tight sm:text-[58px]">
              Pause your Mac
              <br />
              from the couch.
            </h1>
          </Reveal>
          <Reveal delay={160}>
            <p className="mt-6 text-[17px] leading-relaxed text-ink-2">
              Cue turns your iPhone into a remote for whatever your Mac is
              playing. YouTube Music in a Chrome tab, Netflix, VLC: if it
              shows up in Now Playing, your phone can pause it, scrub it, and
              turn it down. Two small Swift apps talking over your Wi-Fi.
              Nothing leaves your network.
            </p>
          </Reveal>
          <Reveal delay={240}>
            <div className="mt-9 flex flex-wrap items-center gap-4">
              <a
                href="#install"
                className="rounded-full bg-ink px-7 py-3 text-[15px] font-bold text-stage transition-transform hover:scale-[1.03]"
              >
                Get started
              </a>
              <a
                href={GITHUB}
                className="flex items-center gap-2.5 rounded-full border border-white/15 px-7 py-3 text-[15px] font-semibold transition-colors hover:border-white/30 hover:bg-white/5"
              >
                <GitHubIcon className="h-[18px] w-[18px]" />
                Read the source
              </a>
            </div>
          </Reveal>
          <Reveal delay={320}>
            <p className="mt-7 text-[13.5px] text-ink-3">
              No cloud, no accounts, no telemetry. There is no server to trust
              because there is no server.
            </p>
          </Reveal>
        </div>
        <Reveal delay={200} className="justify-self-center lg:justify-self-end">
          <PhoneMock />
        </Reveal>
      </div>
    </section>
  );
}

/* ---------- Services strip ---------- */

const SERVICES = [
  "YouTube Music",
  "Netflix",
  "Prime Video",
  "Hotstar",
  "Spotify",
  "VLC",
];

function Services() {
  return (
    <section className="mx-auto max-w-6xl px-5 pt-24 sm:px-8 sm:pt-32">
      <Reveal>
        <p className="text-center text-[13px] font-semibold uppercase tracking-[0.14em] text-ink-3">
          One remote for everything in the Now Playing pipeline
        </p>
        <div className="mt-7 flex flex-wrap items-center justify-center gap-x-10 gap-y-4 text-[17px] font-bold text-ink-2/80">
          {SERVICES.map((s) => (
            <span key={s}>{s}</span>
          ))}
          <span className="text-[14px] font-medium text-ink-3">
            …and anything else Chrome plays
          </span>
        </div>
      </Reveal>
    </section>
  );
}

/* ---------- How it works ---------- */

const STEPS = [
  {
    n: "01",
    title: "Booth sits in your menu bar",
    body: "Cue Booth, the Mac half, reads the system Now Playing pipeline, the same one your keyboard's media keys use. When Chrome registers a playing tab, macOS treats it as the now-playing app, and Booth sees the title, artist, artwork, position, and play state. One mechanism covers every site and app, with zero per-site code.",
  },
  {
    n: "02",
    title: "Your phone finds it by itself",
    body: "Booth advertises over Bonjour on your local network. Open Cue on your iPhone and your Mac just appears. No IP addresses, no QR codes, no config file. The first connection asks for a six-digit pairing code shown on the Mac, and until a client sends the right one, the server stays silent.",
  },
  {
    n: "03",
    title: "Commands ride a direct WebSocket",
    body: "Play, pause, seek, next, volume: small JSON commands from the phone, full state snapshots pushed back from the Mac. Full snapshots instead of diffs means the phone can never drift out of sync; the worst case after a hiccup is one 80 ms update.",
  },
];

function HowItWorks() {
  return (
    <section id="how" className="mx-auto max-w-6xl scroll-mt-24 px-5 pt-28 sm:px-8 sm:pt-36">
      <Reveal>
        <p className="text-[13px] font-bold uppercase tracking-[0.14em] text-rose">
          How it works
        </p>
        <h2 className="mt-3 max-w-2xl text-[32px] font-extrabold leading-tight tracking-tight sm:text-[40px]">
          Two apps, one Wi-Fi network, and that&apos;s the whole architecture.
        </h2>
      </Reveal>
      <div className="mt-14 grid gap-5 md:grid-cols-3">
        {STEPS.map((step, i) => (
          <Reveal key={step.n} delay={i * 100}>
            <div className="h-full rounded-3xl border border-white/[0.07] bg-surface/60 p-8">
              <span className="font-mono text-[13px] font-bold text-peach">
                {step.n}
              </span>
              <h3 className="mt-4 text-[19px] font-bold tracking-tight">
                {step.title}
              </h3>
              <p className="mt-3 text-[14.5px] leading-relaxed text-ink-2">
                {step.body}
              </p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* ---------- Features ---------- */

const FEATURES = [
  {
    title: "Real system volume",
    body: "Cue talks to CoreAudio directly. The first attempt used osascript, which cost about 200 ms per call and queued up hopelessly under a slider drag. Now the slider feels like it's wired to the speaker, because it more or less is.",
  },
  {
    title: "Live Activity + Dynamic Island",
    body: "Transport controls on the lock screen, an animated equalizer while music plays, and a progress bar that keeps ticking while the app is backgrounded. No push entitlement required — it works on a free Apple ID.",
  },
  {
    title: "Album art worth looking at",
    body: "Chrome hands over small, muddy artwork. Booth quietly upgrades music covers to 600 px via the iTunes Search API and caches them per track. Netflix and friends get proper brand cards instead of a gray square.",
  },
  {
    title: "Paired, not exposed",
    body: "The control port stays silent until a client sends the right six-digit code. No banner, no handshake, nothing. A wrong code gets a rejection and a closed connection. Your roommate's laptop can't pause your movie.",
  },
  {
    title: "Reconnects like it never left",
    body: "Dropped Wi-Fi, a restarted Booth, a backgrounded app: the phone retries every two seconds and again the moment it returns to the foreground. Walk to the kitchen and back; the scrubber is still ticking.",
  },
  {
    title: "±15 seconds that actually works",
    body: "Most sites ignore MediaRemote's native skip commands but honor plain seek. So Cue's skip buttons are implemented as relative seeks: current position, plus or minus fifteen. Small hack, works everywhere.",
  },
];

function Features() {
  return (
    <section id="features" className="mx-auto max-w-6xl scroll-mt-24 px-5 pt-28 sm:px-8 sm:pt-36">
      <Reveal>
        <p className="text-[13px] font-bold uppercase tracking-[0.14em] text-rose">
          Features
        </p>
        <h2 className="mt-3 max-w-2xl text-[32px] font-extrabold leading-tight tracking-tight sm:text-[40px]">
          The details are the product.
        </h2>
      </Reveal>
      <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((f, i) => (
          <Reveal key={f.title} delay={(i % 3) * 100}>
            <div className="h-full rounded-3xl border border-white/[0.07] bg-surface/60 p-8 transition-colors hover:border-white/[0.14]">
              <h3 className="text-[17px] font-bold tracking-tight">{f.title}</h3>
              <p className="mt-3 text-[14.5px] leading-relaxed text-ink-2">
                {f.body}
              </p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* ---------- Install ---------- */

function Install() {
  return (
    <section id="install" className="mx-auto max-w-6xl scroll-mt-24 px-5 pt-28 sm:px-8 sm:pt-36">
      <div className="grid items-start gap-12 lg:grid-cols-2">
        <Reveal>
          <p className="text-[13px] font-bold uppercase tracking-[0.14em] text-rose">
            Install
          </p>
          <h2 className="mt-3 text-[32px] font-extrabold leading-tight tracking-tight sm:text-[40px]">
            Build it yourself.
            <br />
            That&apos;s the point.
          </h2>
          <p className="mt-5 text-[15.5px] leading-relaxed text-ink-2">
            There&apos;s no App Store listing and no installer. You clone the
            repo, run the Mac half with Swift Package Manager, and sideload the
            iPhone half with Xcode. A free Apple ID is enough; the app
            re-signs every seven days, which is annoying exactly once a week
            and free the rest of the time.
          </p>
          <p className="mt-4 text-[14px] text-ink-3">
            You&apos;ll need macOS with Xcode, Homebrew, and an iPhone that
            shares Wi-Fi with the Mac.
          </p>
        </Reveal>
        <Reveal delay={120} className="min-w-0">
          <div className="overflow-hidden rounded-2xl border border-white/[0.09] bg-[#0b0a11]">
            <div className="flex items-center gap-1.5 border-b border-white/[0.06] px-4 py-3">
              <span className="h-2.5 w-2.5 rounded-full bg-white/15" />
              <span className="h-2.5 w-2.5 rounded-full bg-white/15" />
              <span className="h-2.5 w-2.5 rounded-full bg-white/15" />
              <span className="ml-3 text-[12px] text-ink-3">terminal</span>
            </div>
            <pre className="overflow-x-auto p-5 font-mono text-[13px] leading-[1.9] text-ink-2">
              <code>
                <span className="text-ink-3"># the one external dependency</span>
                {"\n"}
                <span className="text-go">$</span> brew install media-control
                {"\n\n"}
                <span className="text-ink-3"># Mac: Cue Booth, the menu bar server</span>
                {"\n"}
                <span className="text-go">$</span> git clone {GITHUB}.git
                {"\n"}
                <span className="text-go">$</span> cd cue/booth && swift run
                {"\n\n"}
                <span className="text-ink-3"># iPhone: generate the project, then run from Xcode</span>
                {"\n"}
                <span className="text-go">$</span> cd ../ios && xcodegen generate
                {"\n"}
                <span className="text-go">$</span> open Cue.xcodeproj
              </code>
            </pre>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* ---------- Fine print ---------- */

const FAQ = [
  {
    q: "Why does it need a Homebrew package?",
    a: "Since macOS 15.4, Apple restricts the private MediaRemote framework to entitled processes. media-control is the community workaround: it loads the framework through an Apple-signed perl binary and streams JSON out. It's Cue's only unofficial dependency, and the first thing to check after a macOS update: media-control test tells you in two seconds whether the pipeline survived.",
  },
  {
    q: "Does it work away from home?",
    a: "No, and that's a design choice, not a limitation to fix later. The phone and Mac must share a network and the Mac must be awake. There's no relay, no account, and no way for anyone outside your Wi-Fi to reach the control port.",
  },
  {
    q: "Why isn't it on the App Store?",
    a: "It controls your Mac over a private protocol and depends on a private framework. Not App Store material, and it was never meant to be. Sideloading with a free Apple ID works fine; a paid developer account just removes the weekly re-sign.",
  },
  {
    q: "What doesn't work?",
    a: "\"Next episode\" on Netflix — that's a UI button, not a media-key concept, so no remote can press it through this pipeline. Play, pause, seek, and volume work everywhere. Also honest: keeping the connection alive in the background costs some battery while you're connected.",
  },
];

function FinePrint() {
  return (
    <section id="faq" className="mx-auto max-w-6xl scroll-mt-24 px-5 pt-28 sm:px-8 sm:pt-36">
      <Reveal>
        <p className="text-[13px] font-bold uppercase tracking-[0.14em] text-rose">
          Fine print
        </p>
        <h2 className="mt-3 max-w-2xl text-[32px] font-extrabold leading-tight tracking-tight sm:text-[40px]">
          The caveats, before you find them yourself.
        </h2>
      </Reveal>
      <div className="mt-12 grid gap-5 md:grid-cols-2">
        {FAQ.map((item, i) => (
          <Reveal key={item.q} delay={(i % 2) * 100}>
            <div className="h-full rounded-3xl border border-white/[0.07] bg-surface/40 p-8">
              <h3 className="text-[16.5px] font-bold tracking-tight">{item.q}</h3>
              <p className="mt-3 text-[14.5px] leading-relaxed text-ink-2">
                {item.a}
              </p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* ---------- CTA + footer ---------- */

function Footer() {
  return (
    <footer className="relative mt-32 overflow-hidden border-t border-white/[0.06]">
      <div
        className="glow pointer-events-none absolute -bottom-[300px] left-1/2 h-[600px] w-[1000px] -translate-x-1/2 opacity-25"
        style={{
          background:
            "radial-gradient(closest-side, #d4507a 0%, #5b2a86 55%, transparent 78%)",
        }}
      />
      <div className="relative mx-auto max-w-6xl px-5 py-20 sm:px-8">
        <Reveal>
          <div className="flex flex-col items-center text-center">
            <CueMark className="h-14 w-14" />
            <h2 className="mt-6 text-[28px] font-extrabold tracking-tight sm:text-[34px]">
              Your Mac. Your network. Your remote.
            </h2>
            <p className="mt-3 max-w-md text-[15px] text-ink-2">
              Clone it, break it, send a PR. The whole thing is a few thousand
              lines of Swift you can read in an evening.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-4">
              <a
                href={GITHUB}
                className="flex items-center gap-2.5 rounded-full bg-ink px-7 py-3 text-[15px] font-bold text-stage transition-transform hover:scale-[1.03]"
              >
                <GitHubIcon className="h-[18px] w-[18px]" />
                Star on GitHub
              </a>
              <a
                href={`${GITHUB}/issues`}
                className="rounded-full border border-white/15 px-7 py-3 text-[15px] font-semibold transition-colors hover:border-white/30 hover:bg-white/5"
              >
                Report an issue
              </a>
            </div>
          </div>
        </Reveal>
        <div className="mt-16 flex flex-col items-center justify-between gap-4 border-t border-white/[0.06] pt-8 text-[13px] text-ink-3 sm:flex-row">
          <span>MIT licensed. Built by Niket, mostly from the couch.</span>
          <span>
            Cue for iPhone · Cue Booth for macOS · Not affiliated with any
            service it controls.
          </span>
        </div>
      </div>
    </footer>
  );
}

export default function Home() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <Services />
        <HowItWorks />
        <Features />
        <Install />
        <FinePrint />
      </main>
      <Footer />
    </>
  );
}
