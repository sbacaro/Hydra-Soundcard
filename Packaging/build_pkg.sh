#!/bin/bash
# Hydra Audio — GPL-3.0
# Build a distributable Hydra .pkg installer.
#
# The installer places:
#   • Hydra.app                        → /Applications
#   • HydraVirtualSoundcard.driver     → /Library/Audio/Plug-Ins/HAL
#   • HydraAudioBridge{2A,2B,4,8,16,32,64,128}.driver → /Library/Audio/Plug-Ins/HAL
# and a postinstall script fixes ownership and restarts coreaudiod so every
# device appears immediately. The audio engine runs in-process inside Hydra.app
# (no separate daemon / LaunchAgent). The pkg ships the app, the engine-hub driver
# AND all 8 bridge drivers, so a single install sets up everything — the user never
# runs a script or installs a bridge by hand.
#
# Usage:
#   bash Packaging/build_pkg.sh
#
# Optional env vars for a signed / notarizable release:
#   APP_SIGN_ID        "Developer ID Application: NAME (TEAMID)"  — re-sign app + driver
#   INSTALLER_SIGN_ID  "Developer ID Installer: NAME (TEAMID)"    — sign the .pkg
# Without them the pkg is UNSIGNED (fine for local installs; Gatekeeper will warn
# on other Macs — sign + notarize for public distribution, see Packaging/README.md).

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$PROJECT_DIR/Packaging"
PROJ="$PROJECT_DIR/Hydra.xcodeproj"
BUILD_DIR="$PROJECT_DIR/build"
PRODUCTS="$BUILD_DIR/Build/Products/Release"
STAGE="$BUILD_DIR/pkgroot"
RES="$BUILD_DIR/pkg-resources"
OUT_DIR="$PROJECT_DIR/dist"

PKG_ID="audio.hydra.installer"
APP_NAME="Hydra"
DRIVER_NAME="HydraVirtualSoundcard"
HAL="Library/Audio/Plug-Ins/HAL"

log()  { printf '\033[1;35m[pkg]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[pkg] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

command -v xcodebuild >/dev/null || fail "xcodebuild not found — install Xcode"
[ -d "$PROJ" ] || fail "Hydra.xcodeproj not found — run: ruby Scripts/generate_xcodeproj.rb"

# 1. Build the app (also builds + embeds the driver, the HydraDaemon engine
#    framework and the hydra-plugin-host helper).
log "Building $APP_NAME (Release, universal) — this takes a minute ..."
xcodebuild build \
  -project "$PROJ" -scheme "HydraApp" -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  >/dev/null || fail "xcodebuild failed (build it once in Xcode first to surface errors)"

APP="$PRODUCTS/$APP_NAME.app"
DRIVER="$PRODUCTS/$DRIVER_NAME.driver"
[ -d "$APP" ]    || fail "built app missing: $APP"
[ -d "$DRIVER" ] || fail "built driver missing: $DRIVER"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
log "Version $VERSION"

# 1a. Build the universal Rust Dante bridge and copy it into the App Resources folder.
log "Building Dante Virtual Soundcard bridge (universal) ..."
cargo build --manifest-path "$PROJECT_DIR/Sources/Inferno/Cargo.toml" --release --target aarch64-apple-darwin -p hydra-inferno-bridge >/dev/null || fail "Failed to build Dante bridge for arm64"
cargo build --manifest-path "$PROJECT_DIR/Sources/Inferno/Cargo.toml" --release --target x86_64-apple-darwin -p hydra-inferno-bridge >/dev/null || fail "Failed to build Dante bridge for x86_64"
mkdir -p "$APP/Contents/Resources"
lipo -create \
  "$PROJECT_DIR/Sources/Inferno/target/aarch64-apple-darwin/release/hydra-inferno-bridge" \
  "$PROJECT_DIR/Sources/Inferno/target/x86_64-apple-darwin/release/hydra-inferno-bridge" \
  -output "$APP/Contents/Resources/hydra-inferno-bridge" || fail "Failed to create universal Dante bridge binary"

# 1b. Build the Hydra Audio Bridge drivers. These are separate bundle targets
#     (SKIP_INSTALL=YES) that the HydraApp scheme does NOT build, so we build each
#     explicitly and drop every .driver into one folder. They install alongside the
#     engine-hub driver, so the single pkg sets up all Hydra devices in one shot.
BRIDGES_OUT="$BUILD_DIR/bridges"
rm -rf "$BRIDGES_OUT"; mkdir -p "$BRIDGES_OUT"
BRIDGE_TARGETS=(HydraBridge2A HydraBridge2B HydraBridge4 HydraBridge8 \
                HydraBridge16 HydraBridge32 HydraBridge64 HydraBridge128)
log "Building ${#BRIDGE_TARGETS[@]} Hydra Audio Bridge drivers (universal) ..."
for t in "${BRIDGE_TARGETS[@]}"; do
  # -target (not -scheme) so CONFIGURATION_BUILD_DIR drops the .driver straight
  # into $BRIDGES_OUT. Signing is done below (uniformly with the main driver).
  xcodebuild build \
    -project "$PROJ" -target "$t" -configuration Release \
    CONFIGURATION_BUILD_DIR="$BRIDGES_OUT" \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO \
    >/dev/null || fail "xcodebuild failed for bridge target $t (build once in Xcode to surface errors)"
done

# Collect the built bridge bundles (set -u / bash 3.2 safe — no globbing into arrays).
BRIDGE_DRIVERS=()
while IFS= read -r d; do BRIDGE_DRIVERS+=("$d"); done \
  < <(find "$BRIDGES_OUT" -maxdepth 1 -type d -name 'HydraAudioBridge*.driver' | sort)
[ "${#BRIDGE_DRIVERS[@]}" -ge 1 ] || fail "no bridge drivers were built into $BRIDGES_OUT"
log "Built ${#BRIDGE_DRIVERS[@]} bridge driver(s)."

# 2. Sign the drivers + app. The bridges were built unsigned (CODE_SIGNING_ALLOWED=NO),
#    and Apple Silicon refuses to load an unsigned HAL bundle — so they ALWAYS need at
#    least an ad-hoc signature, even for an unsigned local pkg. With a Developer ID they
#    get the same hardened-runtime signature as the main driver (required to notarize).
if [ -n "${APP_SIGN_ID:-}" ]; then
  log "Codesigning driver + bridges + app with: $APP_SIGN_ID"
  codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$DRIVER"
  for drv in "${BRIDGE_DRIVERS[@]}"; do
    codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$drv"
  done
  codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$APP/Contents/Resources/hydra-inferno-bridge"
  codesign --force --options runtime --timestamp --deep --sign "$APP_SIGN_ID" "$APP"
else
  log "Ad-hoc signing bridge drivers and helper binaries (required to load on Apple Silicon) ..."
  for drv in "${BRIDGE_DRIVERS[@]}"; do
    codesign --force -s - "$drv"
  done
  codesign --force -s - "$APP/Contents/Resources/hydra-inferno-bridge"
fi

# 3. Stage the install layout: app + engine-hub driver + every bridge driver.
log "Staging payload ..."
rm -rf "$STAGE"
mkdir -p "$STAGE/Applications" "$STAGE/$HAL"
cp -R "$APP"    "$STAGE/Applications/"
cp -R "$DRIVER" "$STAGE/$HAL/"
for drv in "${BRIDGE_DRIVERS[@]}"; do
  cp -R "$drv" "$STAGE/$HAL/"
done
log "Staged $(( ${#BRIDGE_DRIVERS[@]} + 1 )) HAL driver(s) (engine hub + bridges)."

# 4. Component pkg (carries the postinstall).
chmod +x "$PKG_DIR/scripts/postinstall"
COMPONENT="$BUILD_DIR/Hydra-component.pkg"
CPLIST="$BUILD_DIR/component.plist"
log "pkgbuild (non-relocatable) ..."
# Force every bundle non-relocatable. Otherwise the installer treats Hydra.app as
# "relocatable", finds the build-products copy (which lives in this iCloud/Google
# Drive folder), and tries to update it IN PLACE — which fails with "Operation not
# permitted" because installd can't write to the cloud-sync filesystem. Marking the
# bundles non-relocatable makes it always install to /Applications + the HAL folder.
pkgbuild --analyze --root "$STAGE" "$CPLIST" >/dev/null
/usr/bin/python3 - "$CPLIST" <<'PY'
import sys, plistlib
path = sys.argv[1]
with open(path, "rb") as f:
    items = plistlib.load(f)
for d in items:
    if isinstance(d, dict):
        d["BundleIsRelocatable"] = False
with open(path, "wb") as f:
    plistlib.dump(items, f)
PY
pkgbuild \
  --root "$STAGE" \
  --component-plist "$CPLIST" \
  --identifier "$PKG_ID" \
  --version "$VERSION" \
  --scripts "$PKG_DIR/scripts" \
  --ownership recommended \
  "$COMPONENT" >/dev/null

# 5. Product archive (installer UI + license). Assemble resources with the
#    repo's LICENSE so the GPL is shown during install.
rm -rf "$RES"; mkdir -p "$RES"
cp "$PKG_DIR"/resources/* "$RES/"
cp "$PROJECT_DIR/LICENSE" "$RES/LICENSE"

mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/Hydra-$VERSION.pkg"
log "productbuild ..."
# (avoid bash 3.2 empty-array-under-`set -u`; branch instead of "${arr[@]}")
if [ -n "${INSTALLER_SIGN_ID:-}" ]; then
  productbuild \
    --distribution "$PKG_DIR/distribution.xml" \
    --resources "$RES" \
    --package-path "$BUILD_DIR" \
    --sign "$INSTALLER_SIGN_ID" \
    "$OUT" >/dev/null
else
  productbuild \
    --distribution "$PKG_DIR/distribution.xml" \
    --resources "$RES" \
    --package-path "$BUILD_DIR" \
    "$OUT" >/dev/null
fi

log "Done → $OUT"
if [ -z "${INSTALLER_SIGN_ID:-}" ]; then
  log "NOTE: this pkg is UNSIGNED — fine to install locally, but other Macs need"
  log "a signed + notarized pkg. See Packaging/README.md."
fi
