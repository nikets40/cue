#!/bin/bash
# Stores a TMDB credential for Cue Booth, which uses it to look up show and
# film posters for Netflix / Prime Video / Hotstar playback.
#
#   tools/set-tmdb-key.sh <v3-api-key-or-v4-bearer-token>
#
# Get one free at https://www.themoviedb.org/settings/api
# Restart Cue Booth afterwards. To remove:
#   defaults delete com.niket.cuebooth tmdbApiKey

set -euo pipefail

if [ $# -lt 1 ] || [ -z "${1:-}" ]; then
  echo "usage: tools/set-tmdb-key.sh <tmdb-key>" >&2
  exit 1
fi

defaults write com.niket.cuebooth tmdbApiKey -string "$1"
echo "TMDB key stored. Restart Cue Booth to pick it up."
