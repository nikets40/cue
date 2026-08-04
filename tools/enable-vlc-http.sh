#!/bin/bash
# Enables VLC's HTTP interface so Cue Booth can browse and control its
# playlist, and shares the generated password with Booth.
#
# Bound to 127.0.0.1 — nothing on the network can reach it. Restart VLC
# afterwards for the change to take effect.
#
# To undo:
#   defaults delete org.videolan.vlc extraintf
#   defaults delete org.videolan.vlc http-password

set -euo pipefail

PASSWORD="$(defaults read com.niket.cuebooth vlcPassword 2>/dev/null || openssl rand -hex 8)"

defaults write org.videolan.vlc extraintf -string "http"
defaults write org.videolan.vlc http-host -string "127.0.0.1"
defaults write org.videolan.vlc http-port -int 8080
defaults write org.videolan.vlc http-password -string "$PASSWORD"
defaults write com.niket.cuebooth vlcPassword -string "$PASSWORD"

echo "VLC web interface enabled on 127.0.0.1:8080 and shared with Cue Booth."
echo "Restart VLC for it to take effect."
