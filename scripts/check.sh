#!/usr/bin/env bash
# Pre-PR validation: run from the repo root. Mirrors CI.
set -euo pipefail
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --fatal-infos
flutter test
