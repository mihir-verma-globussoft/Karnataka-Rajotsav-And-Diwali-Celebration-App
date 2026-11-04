#!/usr/bin/env bash
# Builds the user and admin apps into build/habba_hunt/, for Android and iPhone.
# Run from apps/ar_hunt. Stops at the first failure, and checks what it built.
set -euo pipefail

out=build/habba_hunt
database=jxpedobynwyxdwjlqjwk
mkdir -p "$out"

fail() {
  echo "FAILED: $1" >&2
  exit 1
}

# Checks the compiled Dart code, the only proof of what a build really contains.
verify() {
  local name=$1 code=$2 admin=$3
  # Via a file: with pipefail, `strings | grep -q` fails whenever grep matches.
  strings "$code" > "$code.txt"
  grep -q "$database" "$code.txt" || fail "$name does not use the database"
  # The placing screen is compiled into the admin build only.
  local placing=0
  if grep -qF 'Save here' "$code.txt"; then placing=1; fi
  [ "$placing" = "$admin" ] || fail "$name has the wrong tools (placing=$placing)"
  if grep -qF 'Sample player' "$code.txt"; then fail "$name has demo mode"; fi
  echo "verified $name"
}

build() {
  local name=$1 admin=$2
  local flag=()
  if [ "$admin" = 1 ]; then flag=(--dart-define=HUNT_ADMIN=true); fi
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  flutter build apk --release ${flag[@]+"${flag[@]}"}
  cp build/app/outputs/flutter-apk/app-release.apk "$out/HabbaHunt-$name.apk"
  unzip -q -o -j "$out/HabbaHunt-$name.apk" lib/arm64-v8a/libapp.so -d "$tmp"
  verify "$name.apk" "$tmp/libapp.so" "$admin"

  # A smaller file for sharing: 64-bit phones only, which nearly all AR phones are.
  flutter build apk --release --split-per-abi --target-platform android-arm64 \
    ${flag[@]+"${flag[@]}"}
  cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
    "$out/HabbaHunt-$name-arm64.apk"
  unzip -q -o -j "$out/HabbaHunt-$name-arm64.apk" lib/arm64-v8a/libapp.so -d "$tmp"
  verify "$name-arm64.apk" "$tmp/libapp.so" "$admin"

  flutter build ipa --release --export-method development ${flag[@]+"${flag[@]}"}
  cp build/ios/ipa/*.ipa "$out/HabbaHunt-$name.ipa"
  unzip -q -o "$out/HabbaHunt-$name.ipa" \
    'Payload/Runner.app/Frameworks/App.framework/App' -d "$tmp"
  verify "$name.ipa" "$tmp/Payload/Runner.app/Frameworks/App.framework/App" "$admin"
}

build USER 0
build ADMIN 1
ls -lh "$out"
echo "ALL BUILDS OK"
