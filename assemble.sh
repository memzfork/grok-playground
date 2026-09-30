#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -d parts ]] && compgen -G 'parts/index.part*' > /dev/null; then
  cat parts/index.part* > index.html
  echo "assembled $(wc -c < index.html) bytes -> ./index.html"
else
  echo "No parts/index.part* found. Place the monolithic index.html in the repo root (relative path ./index.html)." >&2
  exit 1
fi
