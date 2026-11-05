#!/usr/bin/env bash
# Builds the one app everyone installs into build/releases/, for Android and
# iPhone. The admin tools are in it, locked behind the organiser PIN.
# Run from the repo root. Stops at the first failure, and checks what it built.
set -euo pipefail

out=build/releases
database=jddpkaxjchxldcpmdrbq
mkdir -p "$out"

fail() {
  echo "FAILED: $1" >&2
  exit 1
}

# Checks the compiled Dart code, the only proof of what a build really contains.
verify() {
  local name=$1 code=$2
  # Via a file: with pipefail, `strings | grep -q` fails whenever grep matches.
  strings "$code" > "$code.txt"
  grep -q "$database" "$code.txt" || fail "$name does not use the database"
  grep -qF 'Save here' "$code.txt" || fail "$name has no placing screen"
  echo "verified $name"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk "$out/GlobusHabba.apk"
unzip -q -o -j "$out/GlobusHabba.apk" lib/arm64-v8a/libapp.so -d "$tmp"
verify GlobusHabba.apk "$tmp/libapp.so"

flutter build ipa --release --export-method development
cp build/ios/ipa/*.ipa "$out/GlobusHabba.ipa"
unzip -q -o "$out/GlobusHabba.ipa" \
  'Payload/Runner.app/Frameworks/App.framework/App' -d "$tmp"
verify GlobusHabba.ipa "$tmp/Payload/Runner.app/Frameworks/App.framework/App"

ls -lh "$out"
echo "ALL BUILDS OK"
