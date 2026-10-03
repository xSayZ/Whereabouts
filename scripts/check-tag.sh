#!/usr/bin/env bash
# Usage: scripts/check-tag.sh v0.3.0   (also v0.3.0-alpha.1, v0.3.0-beta.2)
# A release tag must match the version in Whereabouts.toc and have a CHANGELOG entry.
# Prints the bare version on success.
set -euo pipefail

tag="${1:-}"
if [[ ! "$tag" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)(-(alpha|beta)\.[0-9]+)?$ ]]; then
  echo "tag '$tag' is not vX.Y.Z or vX.Y.Z-alpha.N / vX.Y.Z-beta.N" >&2
  exit 1
fi
version="${BASH_REMATCH[1]}"

toc="$(sed -n 's/^## Version: *//p' Whereabouts.toc | tr -d '\r')"
if [[ "$toc" != "$version" ]]; then
  echo "tag $tag says $version but Whereabouts.toc says '$toc'" >&2
  exit 1
fi
if ! grep -q "^## \[$version\]" CHANGELOG.md; then
  echo "CHANGELOG.md has no entry for $version" >&2
  exit 1
fi
echo "$version"
