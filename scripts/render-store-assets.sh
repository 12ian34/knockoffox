#!/usr/bin/env bash
# Render store-assets/frames/*.html to PNGs at Chrome Web Store dimensions.
# Requires agent-browser connected to a Chromium instance (any session works):
#   agent-browser connect <port>   # or let it launch its own browser
set -euo pipefail
cd "$(dirname "$0")/.."

render() { # file WxH out
  local file=$1 w=$2 h=$3 out=$4
  agent-browser set viewport "$w" "$h" >/dev/null
  agent-browser open "file://$PWD/store-assets/frames/$file" >/dev/null
  agent-browser eval '(async () => { await document.fonts.ready; return "fonts ready"; })()' >/dev/null
  sleep 0.4
  agent-browser screenshot "store-assets/$out" >/dev/null
  echo "store-assets/$out (${w}x${h})"
}

render shot-1.html 1280 800 screenshot-1.png
render shot-2.html 1280 800 screenshot-2.png
render shot-3.html 1280 800 screenshot-3.png
render shot-4.html 1280 800 screenshot-4.png
render shot-5.html 1280 800 screenshot-5.png
render tile-small.html 440 280 promo-tile-small.png
render marquee.html 1400 560 promo-marquee.png
# og image for the landing page (same art, og dimensions)
render marquee.html 1200 630 og.png
