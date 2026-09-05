#!/usr/bin/env bash
# Capture the connected Android device's screen and resize so the longest edge
# is <= 1999 px (Claude's image API rejects anything larger).
#
# Usage: screencap.sh [output_path]
#   default output: /tmp/screen.png
#   set ANDROID_SERIAL=<serial> when more than one device is attached
set -euo pipefail

if ! command -v magick >/dev/null 2>&1 && ! command -v sips >/dev/null 2>&1; then
  cat >&2 <<'EOF'
screencap.sh: neither `magick` (ImageMagick) nor `sips` found on PATH.
Install ImageMagick:
  macOS:    brew install imagemagick
  Debian:   sudo apt install imagemagick
  Windows:  winget install ImageMagick.ImageMagick
EOF
  exit 1
fi

out="${1:-/tmp/screen.png}"
if command -v magick >/dev/null 2>&1; then
  adb exec-out screencap -p | magick - -resize '1999x1999>' "$out"
else
  adb exec-out screencap -p > "$out"
  sips --resampleHeightWidthMax 1999 "$out" >/dev/null
fi
echo "$out"
exit 0
