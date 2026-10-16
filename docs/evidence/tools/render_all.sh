#!/usr/bin/env bash
# render_all.sh - regenerate every terminal screenshot from its transcript.
# transcripts/<name>.log -> screenshots/<name>.png (or <name>_1.png, <name>_2.png ... when long).
# Browser captures (web-*.png) and AWS Console captures (aws-*.png) are never touched; any
# other PNG without a transcript is reported as stale.
set -euo pipefail
EVIDENCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$EVIDENCE/transcripts"; S="$EVIDENCE/screenshots"
find "$S" -maxdepth 1 -name '*.png' ! -name 'web-*' ! -name 'aws-*' -delete
for log in "$T"/*.log; do
  /usr/bin/python3 "$EVIDENCE/tools/termshot.py" "$log" "$S" >/dev/null
done
echo "rendered $(find "$S" -name '*.png' ! -name 'web-*' ! -name 'aws-*' | wc -l) terminal screenshots"
stale=0
while IFS= read -r png; do
  base="$(basename "$png" .png)"
  [ -f "$T/$base.log" ] && continue
  [[ "$base" =~ ^(.*)_[0-9]+$ ]] && [ -f "$T/${BASH_REMATCH[1]}.log" ] && continue
  echo "STALE: $base.png"; stale=1
done < <(find "$S" -name '*.png' ! -name 'web-*' ! -name 'aws-*')
exit $stale
