#!/usr/bin/env zsh
# See pub/prompts.json v1.0.0-RELEASE — shell standards
#
# Recursive scanning utility for consolidation routines
# Default scan depth: 8, configurable up to 10
# Usage: tree.sh [path] [depth]

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

# Configuration
typeset -r DEFAULT_DEPTH=8
typeset -r MAX_DEPTH=10
typeset -r SCRIPT_NAME="${0:t}"

# Parameters
typeset -r SCAN_PATH="${1:-.}"
typeset -r SCAN_DEPTH="${2:-$DEFAULT_DEPTH}"

# Validation
if [[ ! -d "$SCAN_PATH" ]]; then
  print "Error: Directory '$SCAN_PATH' does not exist" >&2
  exit 1
fi

if (( SCAN_DEPTH > MAX_DEPTH )); then
  print "Warning: Depth $SCAN_DEPTH exceeds maximum $MAX_DEPTH, using $MAX_DEPTH" >&2
  typeset -r ACTUAL_DEPTH=$MAX_DEPTH
else
  typeset -r ACTUAL_DEPTH=$SCAN_DEPTH
fi

# Recursive directory scanning
scan_directory() {
  local path="$1"
  local depth="$2"
  local indent="$3"
  
  # Skip hidden directories and common exclusions
  case "${path:t}" in
    .git|node_modules|*.log|.DS_Store)
      return
      ;;
  esac
  
  print "${indent}${path:t}/"
  
  if (( depth > 0 )); then
    # Scan subdirectories
    for dir in "$path"/*(/N); do
      scan_directory "$dir" $((depth - 1)) "  $indent"
    done
    
    # Scan files
    for file in "$path"/*(.N); do
      case "${file:e}" in
        sh|zsh|bash|rb|py|js|md|html|css)
          print "  ${indent}${file:t}"
          ;;
      esac
    done
  fi
}

print "Scanning '$SCAN_PATH' to depth $ACTUAL_DEPTH:"
print "=" * 50

scan_directory "$SCAN_PATH" "$ACTUAL_DEPTH" ""

print "=" * 50
print "Scan complete."