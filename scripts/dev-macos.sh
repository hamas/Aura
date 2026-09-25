#!/usr/bin/env zsh
#
# Aura macOS Development Live Reload & Rebuild Script
# Terminate stale Aura processes, perform incremental/clean build, and launch fresh binary.
#

set -e

# Change directory to repository root
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Terminating stale Aura macOS processes..."
killall Aura 2>/dev/null || true

echo "==> Building macOS target (Aura.xcodeproj)..."
xcodebuild -project "aura-swift/Aura.xcodeproj" -scheme Aura -destination 'platform=macOS' build

# Locate DerivedData build product path
BUILD_PRODUCTS_DIR="$(xcodebuild -project "aura-swift/Aura.xcodeproj" -scheme Aura -destination 'platform=macOS' -showBuildSettings | grep -m1 " BUILD_DIR =" | awk '{print $3}')"
APP_PATH="${BUILD_PRODUCTS_DIR}/Debug/Aura.app"

if [ ! -d "$APP_PATH" ]; then
    APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData/Aura-*/Build/Products/Debug -maxdepth 1 -name "Aura.app" | head -n 1)"
fi

echo "==> Launching fresh macOS app instance: $APP_PATH"
open -n "$APP_PATH"

echo "==> Aura macOS App launched successfully."
