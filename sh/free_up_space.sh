#!/usr/bin/env zsh
# sh/free_up_space.sh - interactively list and remove large files
# Prefer multi-step logic over single-line pipelines.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

search_dir="${{1:-.}}"

if [[ ! -d $search_dir ]]; then
  echo "Error: $search_dir is not a directory" >&2
  exit 1
fi

echo "Scanning '$search_dir' for large files..."
# collect top 10 largest files (size in KB and path)
typeset -a candidates
while IFS= read -r -d $'\0' file; do
  if [[ -f $file ]]; then
    size_kb=$(du -k "$file" 2>/dev/null | awk '{print $1}')
    candidates+=("${{size_kb}}\t${{file}}")
  fi
done < <(find "$search_dir" -type f -print0)

if (( ${#candidates} == 0 )); then
  echo "No files found."
  exit 0
fi

# Sort and show top 10
printf "%2s %-8s %s\n" "#" "kB" "path"
sorted=("${(@s:\n:)$(printf '%s\n' "${{candidates[@]}}" | sort -nr -k1 | head -n 10)}")
i=1
for entry in "${{sorted[@]}}"; do
  size=${{entry%%$'\t'*}}
  path=${{entry#*$'\t'}}
  printf "%2d %-8s %s\n" "$i" "$size" "$path"
  i=$((i + 1))
done

echo
echo "Delete files? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

echo "Enter numbers separated by spaces (e.g., 1 3), or 'all':"
read -r delete_list

if [[ "$delete_list" = "all" ]]; then
  to_delete=( "${{sorted[@]}}" )
else
  to_delete=()
  for token in ${(s: :)delete_list}; do
    if [[ "$token" =~ '^[0-9]+$' ]]; then
      idx=$(( token - 1 ))
      if (( idx >= 0 && idx < ${#sorted} )); then
        to_delete+=( "${{sorted[$idx]}}" )
      else
        echo "Invalid selection: $token"
      fi
    fi
  done
fi

for pair in "${{to_delete[@]}}"; do
  path=${{pair#*$'\t'}}
  if rm -f -- "$path"; then
    echo "Deleted: $path"
  else
    echo "Failed to delete: $path"
  fi
done

echo "Done."