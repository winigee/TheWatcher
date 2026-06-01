#!/usr/bin/env bash
#
# Builds TheWatcher and assembles a double-clickable macOS .app bundle.
#
# Requirements: macOS 13+ and the Swift toolchain (install Xcode, or just the
# Command Line Tools via `xcode-select --install`).
#
# Usage:
#   ./make_app.sh                # release build -> build/TheWatcher.app
#   open build/TheWatcher.app    # launch it
#
set -euo pipefail

APP_NAME="TheWatcher"
CONFIG="release"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# --- sanity checks ----------------------------------------------------------
if ! command -v swift >/dev/null 2>&1; then
  echo "error: 'swift' not found. Install Xcode or run: xcode-select --install" >&2
  exit 1
fi

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: TheWatcher is a macOS app and must be built on macOS." >&2
  exit 1
fi

# --- compile ----------------------------------------------------------------
echo "==> Building $APP_NAME ($CONFIG)…"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "error: built executable not found at $BIN_PATH" >&2
  exit 1
fi

# --- assemble the .app bundle ----------------------------------------------
echo "==> Assembling $APP_NAME.app…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

# Ad-hoc code signature so Gatekeeper lets you run it locally without a
# developer certificate. (You may still need to right-click > Open the first
# time, or run: xattr -dr com.apple.quarantine build/TheWatcher.app)
if command -v codesign >/dev/null 2>&1; then
  echo "==> Ad-hoc signing…"
  codesign --force --deep --sign - "$APP_BUNDLE" || \
    echo "warning: ad-hoc signing failed; the app will still run after you allow it in System Settings > Privacy & Security."
fi

echo ""
echo "Done. Built: $APP_BUNDLE"
echo "Launch with:  open \"$APP_BUNDLE\""
