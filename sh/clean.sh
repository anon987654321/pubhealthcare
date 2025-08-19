#!/usr/bin/env zsh
# sh/clean.sh - remove CRLF, trim trailing spaces, collapse extra blank lines
# See pub/prompts.json — coding_style guidance.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

target="${{1:-.}}"

if [[ ! -d $target ]]; then
  echo "Error: not a directory: $target" >&2
  exit 1
fi

process_file() {
  local f="$1"
  local tmp
  tmp=""$(mktemp)" || { echo "mktemp failed"; return 1; }

  # Stepwise processing for clarity:
  # 1) Remove CR (\r)
  # 2) Trim trailing whitespace per line
  # 3) Collapse multiple blank lines into a single blank line
  tr -d '\r' <"$f" >"${{tmp}}.step1" || return 1

  awk '{ sub(/[ \t]+$/, ""); print }' "${{tmp}}.step1" >"${{tmp}}.step2" || return 1

  awk 'NF { print; last=1 } !NF && last { print ""; last=0 }' "${{tmp}}.step2" >"$tmp" || return 1

  mv -- "$tmp" "$f"
  rm -f -- "${{tmp}}.step1" "${{tmp}}.step2" 2>/dev/null || true
  echo "Cleaned: $f"
}

# Walk and process text files only.
for f in "${{target}}"/**/*(.N); do
  [[ -e $f ]] || continue
  if file -b "$f" 2>/dev/null | grep -q text; then
    process_file "$f" || echo "Failed to process: $f" >&2
  fi
done