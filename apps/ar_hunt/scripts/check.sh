#!/usr/bin/env bash
# Pre-PR validation for the standalone app: run from apps/ar_hunt. The same
# checks as the repo's scripts/check.sh, which does not reach into apps/.
set -euo pipefail
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
