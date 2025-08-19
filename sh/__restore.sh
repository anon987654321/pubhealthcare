#!/usr/bin/env zsh
# sh/__restore.sh - careful, interactive restore helper
# Extract archives from __OLD_BACKUPS, propose mapping, commit per item.
# WARNING: This script performs git commits and file operations. Run locally.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

DEPTH=${1:-8}
backup_dir="__OLD_BACKUPS"

if [[ ! -d $backup_dir ]]; then
  echo "__OLD_BACKUPS not found; nothing to restore."
  exit 0
fi

extract_archive() {
  local archive="$1"
  local tmpdir
  tmpdir="$(mktemp -d)" || { echo "mktemp failed"; return 1; }
  case "$archive" in
    *.tgz|*.tar.gz)
      tar -xzf "$archive" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
      ;;
    *.zip)
      unzip -q "$archive" -d "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
      ;;
    *)
      echo "Unsupported archive type: $archive"
      rm -rf "$tmpdir"
      return 1;
      ;;
  esac
  printf '%s\n' "$tmpdir"
}

# Process archives one by one to keep commits small and reviewable
for arc in "$backup_dir"/**/*(.N); do
  [[ -e $arc ]] || continue
  case "$arc" in
    *.tgz|*.tar.gz|*.zip)
      echo "Processing archive: $arc"
      tmpdir="$(extract_archive "$arc")" || { echo "Failed to extract $arc"; continue; }
      # Find files up to requested depth
      mapfile -t files < <(find "$tmpdir" -type f -maxdepth "$DEPTH" 2>/dev/null)
      if (( ${#files[@]} == 0 )); then
        echo "No files found in $arc (depth $DEPTH)"
        rm -rf "$tmpdir"
        continue
      fi

      for src in "${files[@]}"; do
        rel="${src#$tmpdir/}"
        # Heuristic mapping rules (simple, explicit)
        if [[ "$rel" == *pubhealthcare* ]]; then
          tgt="bplans/pubhealthcare.html"
        elif [[ "$rel" == *.sh ]]; then
          tgt="sh/${rel##*/}"
        elif [[ "$rel" == *.rb ]]; then
          tgt="ai3/${rel##*/}"
        elif [[ "$rel" == *.md || "$rel" == *.html ]]; then
          tgt="bplans/${rel##*/}"
        else
          tgt="restored/${rel##*/}"
        fi

        mkdir -p "$(dirname "$tgt")"
        cp -- "$src" "$tgt"
        git add -- "$tgt"
        if git commit -m "restore: extract $(basename "$arc") -> $tgt"; then
          echo "Committed: $tgt"
        else
          echo "Commit failed for $tgt; aborting restore loop"
          rm -rf "$tmpdir"
          exit 1
        fi
      done

      # Remove the archive from repo and commit the deletion
      if git rm --ignore-unmatch "$arc"; then
        git commit -m "cleanup: remove $arc after restore" || echo "cleanup commit failed"
      else
        echo "git rm skipped or failed for $arc"
      fi

      rm -rf "$tmpdir"
      ;;
    *)
      # not an archive, skip
      ;;
  esac
done

echo "Restore pass complete. Inspect commits before pushing."