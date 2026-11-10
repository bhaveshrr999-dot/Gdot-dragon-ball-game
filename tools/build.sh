#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
case "${1:-test}" in
  test)
    "$GODOT_BIN" --headless --editor --import --quit
    "$GODOT_BIN" --headless --path . --script tests/combat_test.gd
    "$GODOT_BIN" --headless --path . --script tests/menu_input_test.gd
    ;;
  web)
    mkdir -p build/web
    "$GODOT_BIN" --headless --path . --export-release Web
    ;;
  android)
    : "${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK}"
    : "${JAVA_HOME:?Set JAVA_HOME to JDK 17}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set private release keystore path}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set keystore alias}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set keystore password}"
    mkdir -p build/android
    "$GODOT_BIN" --headless --path . --export-release 'Android ARM64'
    python3 tools/verify_apk.py build/android/ultimate-warriors-0.2.0-arm64.apk
    "$ANDROID_HOME/build-tools/35.0.1/apksigner" verify --verbose build/android/ultimate-warriors-0.2.0-arm64.apk
    "$ANDROID_HOME/build-tools/35.0.1/zipalign" -c -P 16 -v 4 build/android/ultimate-warriors-0.2.0-arm64.apk
    (cd build/android && sha256sum ultimate-warriors-0.2.0-arm64.apk > SHA256SUMS)
    ;;
  *) echo 'Usage: tools/build.sh test|web|android' >&2; exit 2 ;;
esac
