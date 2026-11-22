#!/bin/zsh
# One-shot build of XIVLauncher.Core (CN, macOS) with the controller patches.
#
# Usage: scripts/install.sh [OUTPUT_DIR]      (default: ./dist)
# Result: OUTPUT_DIR/XIVLauncher.Core.app
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="${1:-$ROOT/dist}"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || die "Apple Silicon macOS is required."

echo "==> Checking Rosetta 2"
if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  echo "Rosetta 2 is not installed (the bundled Wine is x86_64). Install it with:"
  echo "    softwareupdate --install-rosetta --agree-to-license"
  die "then re-run this script."
fi

echo "==> Checking build dependencies"
command -v brew >/dev/null || die "Homebrew is required: https://brew.sh"
brew bundle --file="$ROOT/Brewfile"
DOTNET_PREFIX="$(brew --prefix dotnet@10)"
export DOTNET_ROOT="$DOTNET_PREFIX/libexec"
export PATH="$DOTNET_PREFIX/bin:$PATH"
export DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1
dotnet --list-sdks | grep -q '^10\.' || die ".NET 10 SDK not found after brew bundle."

echo "==> Fetching submodule and applying patches"
git submodule update --init --recursive
"$ROOT/scripts/apply-patches.sh"

echo "==> Building (this takes a few minutes)"
PUB="$(mktemp -d)"; trap 'rm -rf "$PUB"' EXIT
dotnet publish "$ROOT/src/XIVLauncher.Core" -r osx-arm64 --self-contained -c Release -o "$PUB" >"$ROOT/build.log" 2>&1 \
  || { tail -20 "$ROOT/build.log"; die "build failed, full log: $ROOT/build.log"; }

echo "==> Creating app bundle"
APP="$OUT/XIVLauncher.Core.app"
rm -rf "$APP"; mkdir -p "$APP/Contents"
cp -R "$PUB" "$APP/Contents/MacOS"
VERSION="$(git describe --tags --always 2>/dev/null || git rev-parse --short HEAD)"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>XIVLauncher.Core</string>
  <key>CFBundleIdentifier</key><string>local.xivlauncher.core.mac-controller</string>
  <key>CFBundleName</key><string>XIVLauncher.Core</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
PLIST
xattr -cr "$APP" 2>/dev/null || true

cat <<MSG

Done: $APP

Next steps (controller support):
  1. Open the app, log in and start the game ONCE with the default (Managed) Wine,
     so the launcher downloads Wine 11 and DXMT. Then quit the launcher.
  2. Run: scripts/build-controller-wine.sh --configure
  3. Connect your controller, open the app and start the game.
If the controller is not detected in game: System Settings -> Privacy & Security -> Input Monitoring,
add and enable XIVLauncher.Core.app, then restart the launcher.
MSG
