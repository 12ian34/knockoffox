#!/usr/bin/env bash
# Rasterize icons/icon.svg to the PNG sizes the manifest needs.
# Requires a Chromium-based browser driven by agent-browser, or use any SVG
# rasterizer (e.g. `rsvg-convert -w 128 icons/icon.svg > icons/icon128.png`).
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v rsvg-convert >/dev/null 2>&1; then
  for s in 16 32 48 128; do
    rsvg-convert -w "$s" -h "$s" icons/icon.svg > "icons/icon$s.png"
    echo "icons/icon$s.png"
  done
else
  echo "rsvg-convert not found — install librsvg (brew install librsvg)" >&2
  exit 1
fi
