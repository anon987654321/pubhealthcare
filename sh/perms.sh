#!/usr/bin/env zsh
# sh/perms.sh - change ownership and permissions recursively
# Usage: perms.sh <owner> <group> <file_perms> <folder_perms>
# Query user interactively for confirmation.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

if (( $# < 4 )); then
  echo "Usage: $0 <owner> <group> <file_perms> <folder_perms>" >&2
  exit 1
fi

owner="$1"
group="$2"
file_perms="$3"
folder_perms="$4"

if [[ ! "$file_perms" =~ ^[0-7]{3}$ ]] || [[ ! "$folder_perms" =~ ^[0-7]{3}$ ]]; then
  echo "Error: permissions must be three octal digits" >&2
  exit 1
fi

echo "About to chown to ${owner}:${group}"
echo "File perms: ${file_perms}  Folder perms: ${folder_perms}"
echo -n "Proceed? (y/N): "
read -r ok
if [[ ! "$ok" =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# Apply ownership and permissions in clear steps
find . -type f -print0 | xargs -0 chown "${owner}:${group}" 2>/dev/null || echo "chown files: some failures"
find . -type d -print0 | xargs -0 chown "${owner}:${group}" 2>/dev/null || echo "chown dirs: some failures"

find . -type f -print0 | xargs -0 chmod "$file_perms" 2>/dev/null || echo "chmod files: some failures"
find . -type d -print0 | xargs -0 chmod "$folder_perms" 2>/dev/null || echo "chmod dirs: some failures"

echo "Permissions and ownership updates finished."