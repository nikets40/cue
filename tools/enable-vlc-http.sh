#!/bin/bash
# Enables VLC's HTTP interface so Cue Booth can list and control it, and
# shares the generated password with Booth.
#
#   tools/enable-vlc-http.sh
#
# VLC 3.x reads ~/Library/Preferences/org.videolan.vlc/vlcrc — the macOS
# `defaults` domain is NOT consulted for these settings, so they have to be
# written into that file. VLC rewrites vlcrc when it quits, so it must be
# closed first or the changes are lost.
#
# Bound to 127.0.0.1; nothing on the network can reach it. To undo, re-comment
# the extraintf line in vlcrc.

set -euo pipefail

VLCRC="$HOME/Library/Preferences/org.videolan.vlc/vlcrc"

if pgrep -f "VLC.app/Contents/MacOS/VLC" >/dev/null 2>&1; then
  echo "VLC is running — quit it first (⌘Q), or it will overwrite these settings on exit." >&2
  exit 1
fi

if [ ! -f "$VLCRC" ]; then
  echo "No vlcrc at $VLCRC — launch VLC once, quit it, then re-run." >&2
  exit 1
fi

PASSWORD="$(defaults read com.niket.cuebooth vlcPassword 2>/dev/null || openssl rand -hex 8)"
cp "$VLCRC" "$VLCRC.cue-backup"

# Replace the setting whether it's currently commented out or already set.
set_option() {
  local key="$1" value="$2"
  if grep -qE "^#?${key}=" "$VLCRC"; then
    /usr/bin/sed -i '' -E "s|^#?${key}=.*|${key}=${value}|" "$VLCRC"
  else
    printf '%s=%s\n' "$key" "$value" >> "$VLCRC"
  fi
}

set_option extraintf http
set_option http-host 127.0.0.1
set_option http-port 8080
set_option http-password "$PASSWORD"

defaults write com.niket.cuebooth vlcPassword -string "$PASSWORD"

echo "VLC web interface enabled on 127.0.0.1:8080 (backup: $VLCRC.cue-backup)."
echo "Start VLC and it will be reachable."
