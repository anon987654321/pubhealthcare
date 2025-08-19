#!/usr/bin/env zsh
# sh/tree.sh
# Recursive scanner with configurable depth (default 8)
# See pub/prompts.json — coding_style: prefer simple multi-line constructs

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

usage() {
  cat <<EOF
Usage: $0 [--depth N] [path]
  --depth N : maximum recursion depth (default from env SCAN_DEPTH or 8)
  path      : directory to scan (default .)
EOF
  exit 1
}

DEPTH=${{SCAN_DEPTH:-8}}
path='.'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --depth)
      shift
      DEPTH=$1
      shift
      ;;
    --depth=*)
      DEPTH=${{1#*=}}
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      path=$1
      shift
      ;;
  esac
done

if [[ ! -d $path ]]; then
  echo "Error: $path is not a directory" >&2
  exit 2
fi

walk() {
  local dir="$1"
  local level="$2"

  if (( level > DEPTH )); then
    return 0
  fi

  # List plain files at this level
  for entry in "$dir"/*(.N); do
    [[ -e $entry ]] || continue
    printf '%s\n' "${{entry#./}}"
  done

  # Recurse into subdirectories
  for sub in "$dir"/*(/N); do
    [[ -d $sub ]] || continue
    walk "$sub" $(( level + 1 ))
  done
}

walk "$path" 1