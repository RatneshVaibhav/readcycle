#!/usr/bin/env bash
# build.sh - print docs/report/report.html to docs/ReadCycle-Project-Report.pdf,
# with headless Chrome (fonts come from Google Fonts, so it needs the internet).
#   docs/report/build.sh
set -euo pipefail
cd "$(dirname "$0")"
out=../ReadCycle-Project-Report.pdf
google-chrome --headless=new --disable-gpu --no-sandbox --no-pdf-header-footer \
  --virtual-time-budget=15000 --run-all-compositor-stages-before-draw \
  --print-to-pdf="$out" "file://$PWD/report.html" 2>/dev/null
echo "wrote $(realpath "$out") ($(du -h "$out" | cut -f1))"
