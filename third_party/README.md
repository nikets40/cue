# Third-party components

## media-control

Cue Booth vendors [`media-control`](https://github.com/ungive/media-control) by
Jonas van den Berg into its app bundle, along with the `mediaremote-adapter`
framework it drives. That is what lets Booth read macOS now-playing state after
Apple restricted the API in macOS 15.4.

Licensed **BSD 3-Clause**, © 2025 Jonas van den Berg and contributors — see
`media-control-LICENSE.txt`, which is copied into the app bundle so the notice
travels with any redistributed build, as the licence requires.

A note on where that text came from: `ungive/media-control` states BSD 3-Clause
in its README but its `LICENSE` link is broken and the file is absent from the
repository, so GitHub reports no licence for it. The text here is taken from the
companion `ungive/mediaremote-adapter` repository — same author, same licence,
and the copy that is actually published.
