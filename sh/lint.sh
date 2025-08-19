#!/usr/bin/env zsh
# sh/lint.sh - run linters on Ruby files (rubocop, reek) where available
# Non-fatal: report issues but continue.

set -euo pipefail
emulate -L zsh
setopt extended_glob null_glob

check_tool() {
  command -v "$1" >/dev/null 2>&1
}

lint_ruby_file() {
  local file="$1"
  echo "Lint: $file"

  if check_tool rubocop; then
    if rubocop --auto-correct "$file"; then
      echo "rubocop: OK $file"
    else
      echo "rubocop: issues in $file"
    fi
  else
    echo "rubocop not installed; skipping"
  fi

  if check_tool reek; then
    if reek "$file" >/dev/null 2>&1; then
      echo "reek: OK $file"
    else
      echo "reek: issues in $file"
    fi
  else
    echo "reek not installed; skipping"
  fi
}

for f in **/*.(rb|erb)(.N); do
  [[ -e $f ]] || continue
  lint_ruby_file "$f"
done