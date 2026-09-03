#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required. Expected version: $(cat .flutter-version)" >&2
  exit 1
fi

needs_generation=false
for required in android ios .metadata; do
  if [[ ! -e "$required" ]]; then
    needs_generation=true
  fi
done

if [[ "$needs_generation" == true ]]; then
  temp_root="$(mktemp -d)"
  trap 'rm -rf "$temp_root"' EXIT

  flutter create \
    --platforms=android,ios \
    --org=com.frainzzel \
    --project-name=photo_cut \
    --description='Print one photo repeatedly at an exact physical size.' \
    "$temp_root/photo_cut"

  [[ -d android ]] || cp -R "$temp_root/photo_cut/android" android
  [[ -d ios ]] || cp -R "$temp_root/photo_cut/ios" ios
  [[ -f .metadata ]] || cp "$temp_root/photo_cut/.metadata" .metadata
fi

python3 tool/normalize_platforms.py

echo "Android/iOS platform scaffolds are present and normalised."
