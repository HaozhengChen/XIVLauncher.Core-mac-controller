#!/bin/zsh
# Build a "controller-enabled" Wine for XIVLauncher.Core (macOS).
#
# Managed Wine 11 ships winemetal (needed by DXMT) but its winebus has no SDL
# backend, so game controllers never show up in FFXIV. Gcenx's Wine Stable has
# the SDL backend but no winemetal, so DXMT cannot start the game. This script
# copies the managed Wine and swaps in only the SDL-enabled winebus pieces.
#
# Usage: scripts/build-controller-wine.sh [MANAGED_WINE_DIR] [OUTPUT_DIR]
set -euo pipefail

MANAGED="${1:-$HOME/.xlcore_cn/compatibilitytool/beta/wine-11.0}"
OUT="${2:-$HOME/.xlcore_cn/controller-wine}"
VER="11.0_1"
URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/$VER/wine-stable-$VER-osx64.tar.xz"
SHA256="b50dc50ec7f41d58b115a6b685d4d1315ba3c797bd3aa0f49213f2703cb82388"

[[ -x "$MANAGED/bin/wine64" ]] || { echo "Managed Wine not found: $MANAGED (launch the game once with Managed Wine first)"; exit 1; }
[[ -e "$OUT" ]] && { echo "Output already exists: $OUT (remove it first)"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "Downloading Gcenx Wine Stable $VER ..."
curl -fL --progress-bar -o "$TMP/wine.tar.xz" "$URL"
echo "$SHA256  $TMP/wine.tar.xz" | shasum -a 256 -c -
tar -xf "$TMP/wine.tar.xz" -C "$TMP"
G="$(echo "$TMP"/*.app/Contents/Resources/wine)"
[[ -d "$G" ]] || { echo "Unexpected archive layout"; exit 1; }

echo "Copying managed Wine to $OUT ..."
cp -cR "$MANAGED" "$OUT"
cp "$G/lib/wine/x86_64-unix/winebus.so"     "$OUT/lib/wine/x86_64-unix/winebus.so"
cp "$G/lib/wine/x86_64-windows/winebus.sys" "$OUT/lib/wine/x86_64-windows/winebus.sys"
cp "$G/lib/libSDL2-2.0.0.dylib" "$G/lib/libinotify.0.dylib" "$OUT/lib/"

cat <<MSG

Done. In XIVLauncher.Core -> Settings -> Wine:
  Wine version:      Custom
  Wine binary path:  $OUT/bin
  DXMT:              enabled
Connect the controller before starting the game.
MSG
