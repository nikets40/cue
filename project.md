# Cue

**Cue** is a personal app pair: an iPhone app (**Cue**) that remotely controls system media playback on the owner's Mac, served by a Mac menu bar companion app (**Cue Booth**). Primary target: media playing in Google Chrome (YouTube Music, Netflix, Hotstar, Prime Video, etc.); secondary: VLC. Personal use only — no App Store distribution planned.

> **For agents picking this up fresh:** read this whole file. It contains every decision made so far, the current status, and the milestone list. Update the **Status** section and milestone checkboxes as you complete work.

## Status

_Last updated: 2026-08-04_

- ✅ **M0 complete.** `media-control` 0.7.6 (Homebrew) validated on macOS 26.5.1 (Tahoe): reads full now-playing metadata (title/artist/album/artwork/position/duration/playing) from Chrome, streams diff updates, and sends transport commands (play/pause/next/prev/**seek/shuffle/repeat**) — all without accessibility permissions. `media-control test` passes.
- ✅ **M0.5 complete.** Cue Booth verification dashboard (`booth/`, `swift run`) works against live Chrome playback: artwork, metadata, source app, extrapolated progress + seek, transport buttons, volume slider, raw payload inspector, auto-restarting stream subprocess.
- ✅ **M1 complete.** CueKit protocol package + WebSocket server (`CueServer`, NWListener, port 41952) advertised via Bonjour (`_cue._tcp`, visible in `dns-sd -B _cue._tcp`), full-state broadcast on change (80 ms debounce), commands handled, new clients get an immediate snapshot, menu bar presence, server status badge in dashboard. End-to-end verified with a `URLSessionWebSocketTask` test client: connect → snapshot received; `{"action":"play"}` → Chrome resumed; `{"action":"setVolume","value":45}` → system volume changed; state updates pushed back. Remote: https://github.com/nikets40/cue (private).
- ✅ **M2 complete.** Cue iOS app (`ios/`, XcodeGen project — run `xcodegen generate` in `ios/` to (re)create `Cue.xcodeproj`; the project file and generated Info.plist are gitignored). SwiftUI + Network.framework: `CueClient` (NWBrowser discovery, NWConnection WebSocket straight to the Bonjour endpoint, auto-connect when exactly one Booth is found), DiscoveryView, RemoteView (artwork, track info, extrapolated scrubber + seek, transport row, volume slider). Verified in iPhone 17 Pro Simulator (iOS 26.5) against live Booth: discovery found "MacBook Pro", auto-connected, rendered live Chrome playback with ticking progress; `lsof` confirmed the established WebSocket. **Not yet machine-verified: tapping transport buttons (no accessibility perms for UI automation) — code path identical to the tested wstest client; user should tap-test.** Build: `xcodebuild -project Cue.xcodeproj -scheme Cue -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build`.
- ✅ **M3 complete.** (1) Real-device sideload done by the user (team `H5NF35596Y`, now persisted in `ios/project.yml` so `xcodegen generate` keeps signing). (2) **Pairing token**: server stays silent until a `ClientHello` with the right 6-digit code arrives (code shown in Booth dashboard footer; Booth persists it in `defaults` domain `com.niket.cuebooth` key `pairingToken`; phone stores it as `boothToken` in UserDefaults after pairing). Wrong code → `authFailed` + disconnect; phone shows a pairing screen. Verified via wstest (silence / authFailed / snapshot+commands) and in the Simulator (pairing screen, then token-injected auto-connect). (3) **Auto-reconnect**: phone retries dropped connections every 2 s and on returning to foreground — verified by restarting Booth mid-session. (4) **Launch at login** toggle in Booth dashboard (writes a LaunchAgent at `~/Library/LaunchAgents/com.niket.cuebooth.plist` pointing at the current binary).
- ⬜ Remaining phase-1 odds and ends: user's walk-around-the-house test; Booth is still run via `swift run` (bundle it properly when vendoring the adapter in phase 2).
- ⬜ Next: **Phase 2** — Live Activity / Dynamic Island, Chrome extension, VLC niceties, vendor mediaremote-adapter.

## Why this architecture

A Chrome-extension-only design can't touch system volume or VLC. Instead, macOS's system-wide "Now Playing" pipeline is used: Chrome registers playing tabs via the Media Session API, and macOS treats that tab as *the* now-playing app. One mechanism controls everything (Chrome sites, VLC, Music.app) with zero per-site code.

- **Now-playing metadata + transport commands**: the private `MediaRemote` framework. Since macOS 15.4 Apple restricts it to entitled processes; the community workaround is [`ungive/mediaremote-adapter`](https://github.com/ungive/mediaremote-adapter) (loads the framework through an Apple-signed `/usr/bin/perl`, streams JSON). We currently consume it via the [`media-control`](https://github.com/ungive/media-control) CLI (`brew install media-control`, installed at `/opt/homebrew/bin/media-control`). **This is the only unofficial dependency and the #1 breakage risk on macOS updates.** Fallback if it dies: AppleScript asking Chrome for tab info (degraded metadata; controls could fall back to synthetic media-key CGEvents).
- **System volume**: `osascript` for now; upgrade to CoreAudio later.
- **VLC**: its built-in HTTP interface (enable in VLC prefs) for playlist browsing; transport also works via the Now Playing pipeline anyway.
- **Phone ↔ Mac link**: Bonjour discovery + WebSocket on LAN (Network.framework both sides). Mac pushes full `NowPlayingState` snapshots (no diffing on the wire = no sync bugs); phone sends small commands (`play`, `pause`, `next`, `previous`, `seek(to:)`, `setVolume(_:)`).

## Repo layout

```
cue/
  project.md          ← you are here
  booth/              ← Cue Booth, macOS app (SPM executable; `cd booth && swift run`)
  CueKit/             ← (M1) shared Swift package: protocol models used by both apps
  ios/                ← (M2) Cue iOS app, Xcode project
```

## Key decisions

| Decision | Choice |
|---|---|
| Names | iPhone app **Cue**, Mac app **Cue Booth** |
| iOS deployment | **Free Apple ID sideload** via Xcode (7-day re-sign; no push entitlement) |
| Mac app style | Menu bar app (`MenuBarExtra`), unsandboxed, SPM executable for now |
| Wire format | JSON over WebSocket; full-state pushes from Mac, commands from phone |
| MediaRemote access | `media-control` CLI subprocess (stream + commands); vendor the adapter framework directly in a later milestone |
| Security | Pairing token on first connect (M3) — don't leave an open control port on Wi-Fi |

## Phases & milestones

### Phase 1 — transport + volume + metadata (core remote)

- [x] **M0 — Validate mediaremote-adapter on macOS 26.** Done 2026-08-04, see Status.
- [x] **M0.5 — Cue Booth verification UI.** Mac app with a dashboard window showing everything the adapter picks up (artwork, title, artist, album, source app, live progress, play state, raw event JSON) plus transport buttons, seek, and a volume slider to verify the command path. No networking yet.
- [x] **M1 — Cue Booth server core.** CueKit protocol package; WebSocket server (`NWListener`) + Bonjour advertising (`_cue._tcp`); broadcast state snapshots; handle commands. Menu bar presence. (Note: websocat misbehaved in this shell — test with a Swift `URLSessionWebSocketTask` script instead; see git history for `wstest.swift` approach.)
- [x] **M2 — Cue iPhone app (Simulator).** SwiftUI: discovery screen (Bonjour browse), remote screen (artwork card, transport, scrubber, volume slider). Simulator talks to Booth on localhost.
- [x] **M3 — Real device + polish.** Sideload to iPhone; pairing token; launch-at-login for Booth; reconnect handling; walk-around-the-house test (user-verified).

### Phase 2 — the nice-to-haves

- [ ] **Live Activity + Dynamic Island** — lock-screen now-playing card with play/pause/next via App Intents (interactive buttons work on free accounts; *content* updates while backgrounded are limited without push entitlement — buttons always work, track info refreshes on interaction/foreground. If stale titles annoy, the $99 dev account fixes it with no architecture change).
- [ ] **Chrome extension** — native messaging host in Cue Booth; playlist browsing, like/dislike, "play playlist X" for YouTube Music first. Brittle per-site DOM scripting; keep isolated.
- [ ] **VLC niceties** — playlist view + file seeking via VLC's HTTP interface.
- [ ] **Vendor mediaremote-adapter** — bundle the framework + perl script inside Cue Booth.app instead of depending on brew.

## Dev environment notes

- Mac: macOS 26.5.1 (Tahoe), Apple Silicon, Xcode at `/Applications/Xcode.app`, Swift 6.3, Homebrew at `/opt/homebrew`.
- `media-control` installed via `brew install media-control`.
- Useful: `media-control get --no-artwork | jq`, `media-control stream --no-artwork`, `media-control test` (exit 0 = adapter functional — run this first after any macOS update).
- Run the Mac app: `cd booth && swift run`.

## Caveats (accepted)

- 7-day re-sign ritual for the free Apple ID iOS install.
- Phone and Mac must share a network; Mac must be awake (no Wake-on-LAN in scope).
- MediaRemote adapter may break on a future macOS update (see fallback above).
- "Next episode" on Netflix isn't a media-key concept; fine — play/pause/seek work.
