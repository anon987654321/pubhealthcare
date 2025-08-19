#!/usr/bin/env zsh
# sh/svgomg.sh - optimize .svg files using svgo (if available)
# Follows coding_style: explicit checks, clear steps.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

if ! command -v svgo >/dev/null 2>&1; then
  echo "Error: svgo not found; install via npm (recommended)" >&2
  exit 1
fi

dir="${{1:-.}}"
if [[ ! -d $dir ]]; then
  echo "Error: $dir is not a directory" >&2
  exit 1
fi

for svg in "$dir"/**/*.svg(.N); do
  [[ -e $svg ]] || continue
  if svgo --pretty "$svg" 2>>"$HOME/script_errors.log"; then
    echo "Processed: $svg"
  else
    echo "Failed to process: $svg"
  fi
done