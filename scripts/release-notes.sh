#!/usr/bin/env bash
# Usage: scripts/release-notes.sh 0.3.0
# Prints the CHANGELOG.md section for that version (used as the GitHub release notes).
set -euo pipefail

version="${1:-}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "usage: $0 X.Y.Z" >&2; exit 1; }

notes="$(awk -v v="$version" '
  $0 ~ "^## \\[" v "\\]" { on = 1; next }
  on && /^## \[/        { exit }
  on                    { print }
' CHANGELOG.md | sed '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"

if [[ -z "$notes" ]]; then
  echo "no CHANGELOG.md section for $version" >&2
  exit 1
fi
printf '%s\n' "$notes"
