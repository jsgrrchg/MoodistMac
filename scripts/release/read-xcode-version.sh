#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-Moodist.xcodeproj}"
SCHEME="${SCHEME:-MoodistMac}"
CONFIGURATION="${CONFIGURATION:-Release}"

build_settings="$(
  xcodebuild -showBuildSettings \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION"
)"

setting() {
  local key="$1"

  awk -F' = ' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "$" { value = $2 }
    END {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      print value
    }
  ' <<< "$build_settings"
}

version="$(setting MARKETING_VERSION)"
build="$(setting CURRENT_PROJECT_VERSION)"
bundle_id="$(setting PRODUCT_BUNDLE_IDENTIFIER)"
deployment_target="$(setting MACOSX_DEPLOYMENT_TARGET)"

if [[ -z "$version" || -z "$build" || -z "$bundle_id" || -z "$deployment_target" ]]; then
  echo "Unable to read release metadata from Xcode build settings." >&2
  echo "version=$version build=$build bundle_id=$bundle_id deployment_target=$deployment_target" >&2
  exit 1
fi

printf 'version=%s\n' "$version"
printf 'build=%s\n' "$build"
printf 'bundle_id=%s\n' "$bundle_id"
printf 'deployment_target=%s\n' "$deployment_target"
