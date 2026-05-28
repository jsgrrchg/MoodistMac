#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <tag> <marketing-version> <build-number> [changelog]" >&2
  exit 64
fi

tag="$1"
version="$2"
build="$3"
changelog="${4:-CHANGELOG.md}"
appcast="${APPCAST_PATH:-appcast.xml}"

if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Release tag must use vX.Y.Z format: $tag" >&2
  exit 1
fi

expected_version="${tag#v}"
if [[ "$version" != "$expected_version" ]]; then
  echo "Tag $tag does not match MARKETING_VERSION $version." >&2
  exit 1
fi

if [[ ! "$build" =~ ^[0-9]+$ || "$build" -lt 1 ]]; then
  echo "CURRENT_PROJECT_VERSION must be a positive integer: $build" >&2
  exit 1
fi

if [[ ! -f "$changelog" ]]; then
  echo "Missing changelog: $changelog" >&2
  exit 1
fi

if ! awk -v version="$version" '
  $0 == "## [" version "]" || index($0, "## [" version "] ") == 1 { found = 1 }
  END { exit found ? 0 : 1 }
' "$changelog"; then
  echo "CHANGELOG.md does not contain a section for $version." >&2
  exit 1
fi

if [[ -f "$appcast" ]]; then
  if grep -Fq "<sparkle:shortVersionString>$version</sparkle:shortVersionString>" "$appcast"; then
    echo "appcast already contains version $version. Refusing to create a duplicate update." >&2
    exit 1
  fi

  highest_build="$(
    grep -o '<sparkle:version>[0-9][0-9]*</sparkle:version>' "$appcast" \
      | sed -E 's#</?sparkle:version>##g' \
      | sort -n \
      | tail -1 \
      || true
  )"
  highest_build="${highest_build:-0}"

  if [[ "$build" -le "$highest_build" ]]; then
    echo "CURRENT_PROJECT_VERSION $build must be greater than highest appcast build $highest_build." >&2
    exit 1
  fi
fi

echo "Release metadata is valid for $tag (version $version, build $build)."
