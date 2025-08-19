#!/usr/bin/env zsh
# sh/backup.sh - create per-subfolder dated tar.gz backups when content changed
# Keeps a checksum store to avoid redundant backups.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

dir="${{1:-.}}"
checksum_file="${{dir}}/.backup_checksums"
date_tag="$(date +%Y%m%d)"

cd "$dir" || { echo "Cannot cd to $dir"; exit 1; }

declare -A old_checksums
if [[ -f $checksum_file ]]; then
  while IFS=' ' read -r folder checksum; do
    old_checksums["$folder"]="$checksum"
  done <"$checksum_file"
fi

declare -A new_checksums

for sub in */(N); do
  [[ -d $sub ]] || continue
  folder="${sub%/}"

  # compute checksum of all files in the folder
  checksum=$(
    find "$folder" -type f -print0 \
      | xargs -0 md5 -q 2>/dev/null \
      | sort \
      | md5 -q 2>/dev/null
  )

  new_checksums["$folder"]="$checksum"

  backup_file="${folder}_${date_tag}.tgz"
  if [[ -z "${old_checksums[$folder]:-}" || "${old_checksums[$folder]}" != "$checksum" ]]; then
    echo "Backing up: $folder -> $backup_file"
    tar -czf "$backup_file" "$folder" 2>/dev/null && echo "Created: $backup_file" || echo "Backup failed: $backup_file"
  else
    echo "Skipped (no change): $folder"
  fi
done

# write new checksums
{
  for k in "${(k)new_checksums}"; do
    echo "$k ${new_checksums[$k]}"
  done
} >"$checksum_file"