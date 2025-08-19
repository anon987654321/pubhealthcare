#!/usr/bin/env zsh
# sh/replace.sh - replace text or rename filename patterns
# Usage: replace.sh [-b] [-f] <old> <new> [folder]
# -b : backup file before replacing content
# -f : treat old/new as filename substrings (rename files)

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

backup=false
is_filename=false

while [[ $# -gt 0 && "${{1:0:1}}" = "-" ]]; do
  case "$1" in
    -b) backup=true; shift;;
    -f) is_filename=true; shift;;
    -h|--help) echo "Usage: $0 [-b] [-f] <old> <new> [folder]"; exit 0;;
    *) break;;
  esac
done

if (( $# < 2 )); then
  echo "Usage: $0 [-b] [-f] <old> <new> [folder]" >&2
  exit 1
fi

old="$1"
new="$2"
folder="${{3:-.}}"

if [[ ! -d $folder ]]; then
  echo "Error: not a directory: $folder" >&2
  exit 1
fi

if $is_filename; then
  # Rename files whose names contain $old -> replace with $new
  for file in "$folder"/**/*(.N); do
    [[ -e $file ]] || continue
    base="$(basename -- "$file")"
    if [[ "$base" = *"$old"* ]]; then
      newname="${{file//$old/$new}}"
      if [[ "$file" != "$newname" ]]; then
        if [[ -e "$newname" ]]; then
          echo "Skipping rename; target exists: $newname"
        else
          mv -- "$file" "$newname" && echo "Renamed: $file -> $newname"
        fi
      fi
    fi
  done
else
  # Replace content in text files
  for file in "$folder"/**/*(.N); do
    [[ -e $file ]] || continue
    if file -b "$file" 2>/dev/null | grep -q text; then
      if grep -q -- "$old" "$file" 2>/dev/null; then
        if $backup; then
          cp -- "$file" "$file.bak"
        fi
        tmp=""$(mktemp)" || { echo "mktemp failed"; exit 1; }
        sed "s|$old|$new|g" "$file" >"$tmp" && mv -- "$tmp" "$file"
        echo "Updated: $file"
      fi
    fi
  done
fi