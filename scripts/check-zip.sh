#!/usr/bin/env bash
# Usage: scripts/check-zip.sh dist/Whereabouts-0.3.0.zip
# A player zip must hold one folder, Whereabouts/, with every file the .toc lists, and nothing from the repo.
set -euo pipefail

zip="${1:?usage: $0 file.zip}"
listing="$(unzip -Z1 "$zip")"

bad="$(grep -vE '^Whereabouts(/|$)' <<<"$listing" || true)"
[[ -z "$bad" ]] || { echo "files outside Whereabouts/: $bad" >&2; exit 1; }

for need in Whereabouts/Whereabouts.toc Whereabouts/Bindings.xml Whereabouts/README.md Whereabouts/CHANGELOG.md; do
  grep -qx "$need" <<<"$listing" || { echo "missing $need" >&2; exit 1; }
done

toc="$(unzip -p "$zip" Whereabouts/Whereabouts.toc | tr -d '\r')"
while read -r f; do
  grep -qx "Whereabouts/$f" <<<"$listing" || { echo "TOC lists $f but it is not in the zip" >&2; exit 1; }
done < <(grep -E '^[^#[:space:]].*\.(lua|xml)$' <<<"$toc")

leak="$(grep -E '^Whereabouts/(tests|docs|scripts|\.github|dist)/|Makefile|CLAUDE\.md|\.luacheckrc|\.pkgmeta|CONTRIBUTING|SECURITY' <<<"$listing" || true)"
[[ -z "$leak" ]] || { echo "repo files leaked into the player zip: $leak" >&2; exit 1; }
echo "zip layout ok ($(grep -vc '/$' <<<"$listing") files)"
