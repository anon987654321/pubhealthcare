#!/usr/bin/env zsh
# sh/showp.sh - create a markdown snapshot of text files in repo
# Produces an OUTPUT_<repo>_<timestamp>.md in $HOME.
# See pub/prompts.json coding_style.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

root=$(basename "$PWD")
date=$(date +"%Y-%m-%d_%H%M%S")
output="$HOME/OUTPUT_${{root}}_${{date}}.md"

write_header() {
  echo "# Snapshot of $root"
  echo "Generated: $(date --iso-8601=seconds 2>/dev/null || date)"
  echo
}

{
  write_header
  for file in **/*(.N); do
    [[ -e $file ]] || continue
    [[ "$file" = "$output" ]] && continue
    if file -b "$file" 2>/dev/null | grep -q text; then
      echo "## \\`${{file#./}}\\``"
      echo '```
      # use cat and guard failures
      if ! cat -- "$file"; then
        echo "Read failed: $file"
      fi
      echo '```
      echo
    fi
  done
} >"$output" 2>>"$HOME/script_errors.log" && echo "Saved: $output" || { echo "Failed to write $output"; exit 1; }
