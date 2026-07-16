#!/bin/bash
# Hydra Audio — GPL-3.0
# Build a native macOS SwiftUI installer app for Hydra and package it in a DMG.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$PROJECT_DIR/Packaging"
PROJ="$PROJECT_DIR/Hydra.xcodeproj"
BUILD_DIR="$PROJECT_DIR/build"
PRODUCTS="$BUILD_DIR/Build/Products/Release"
PAYLOAD="$BUILD_DIR/payload"
STAGE_APP="$BUILD_DIR/staging/Hydra Installer.app"
OUT_DIR="$PROJECT_DIR/dist"

APP_NAME="Hydra"
DRIVER_NAME="HydraVirtualSoundcard"
MIN_MACOS="13.0"

log()  { printf '\033[1;35m[installer-build]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[installer-build] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

command -v xcodebuild >/dev/null || fail "xcodebuild not found — install Xcode"
[ -d "$PROJ" ] || fail "Hydra.xcodeproj not found — run: ruby Scripts/generate_xcodeproj.rb"

# ── 1. Read Version ──────────────────────────────────────────────────────────
VERSION="$(sed -nE 's/.*static let version = "([^"]+)".*/\1/p' "$PROJECT_DIR/Sources/HydraCore/HydraConstants.swift" | head -1)"
[ -n "$VERSION" ] || VERSION="0.0.0"
log "Version resolved from HydraConstants.swift: $VERSION"

# ── 2. Build Core Components ──────────────────────────────────────────────────
log "Building $APP_NAME (Release, universal)..."
xcodebuild build \
  -project "$PROJ" -scheme "HydraApp" -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  >/dev/null || fail "xcodebuild failed for HydraApp"

APP="$PRODUCTS/$APP_NAME.app"
DRIVER="$PRODUCTS/$DRIVER_NAME.driver"
[ -d "$APP" ]    || fail "built app missing: $APP"
[ -d "$DRIVER" ] || fail "built driver missing: $DRIVER"

# ── 3. Build Dante Bridge ─────────────────────────────────────────────────────
log "Building Dante Virtual Soundcard bridge (universal)..."
cargo build --manifest-path "$PROJECT_DIR/Sources/Inferno/Cargo.toml" --release --target aarch64-apple-darwin -p hydra-inferno-bridge >/dev/null || fail "Failed to build Dante bridge for arm64"
cargo build --manifest-path "$PROJECT_DIR/Sources/Inferno/Cargo.toml" --release --target x86_64-apple-darwin -p hydra-inferno-bridge >/dev/null || fail "Failed to build Dante bridge for x86_64"
mkdir -p "$APP/Contents/Resources"
lipo -create \
  "$PROJECT_DIR/Sources/Inferno/target/aarch64-apple-darwin/release/hydra-inferno-bridge" \
  "$PROJECT_DIR/Sources/Inferno/target/x86_64-apple-darwin/release/hydra-inferno-bridge" \
  -output "$APP/Contents/Resources/hydra-inferno-bridge" || fail "Failed to create universal Dante bridge binary"

# ── 4. Build Loopback Bridge Drivers ──────────────────────────────────────────
BRIDGES_OUT="$BUILD_DIR/bridges"
rm -rf "$BRIDGES_OUT"; mkdir -p "$BRIDGES_OUT"
BRIDGE_TARGETS=(HydraBridge2A HydraBridge2B HydraBridge4 HydraBridge8 \
                HydraBridge16 HydraBridge32 HydraBridge64 HydraBridge128)
log "Building ${#BRIDGE_TARGETS[@]} Hydra Audio Bridge drivers (universal)..."
for t in "${BRIDGE_TARGETS[@]}"; do
  xcodebuild build \
    -project "$PROJ" -target "$t" -configuration Release \
    CONFIGURATION_BUILD_DIR="$BRIDGES_OUT" \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO \
    >/dev/null || fail "xcodebuild failed for bridge target $t"
done

BRIDGE_DRIVERS=()
while IFS= read -r d; do BRIDGE_DRIVERS+=("$d"); done \
  < <(find "$BRIDGES_OUT" -maxdepth 1 -type d -name 'HydraAudioBridge*.driver' | sort)
[ "${#BRIDGE_DRIVERS[@]}" -ge 1 ] || fail "no bridge drivers were built"

# ── 5. Stage Payload ──────────────────────────────────────────────────────────
log "Staging payload..."
rm -rf "$PAYLOAD"
mkdir -p "$PAYLOAD/Applications" "$PAYLOAD/HAL"
cp -R "$APP"    "$PAYLOAD/Applications/"
cp -R "$DRIVER" "$PAYLOAD/HAL/"
for drv in "${BRIDGE_DRIVERS[@]}"; do
  cp -R "$drv" "$PAYLOAD/HAL/"
done

# ── 6. Codesign Payload ───────────────────────────────────────────────────────
if [ -n "${APP_SIGN_ID:-}" ]; then
  log "Codesigning payload with Developer ID: $APP_SIGN_ID"
  codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$PAYLOAD/HAL/$DRIVER_NAME.driver"
  for drv in "$PAYLOAD"/HAL/HydraAudioBridge*.driver; do
    codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$drv"
  done
  codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$PAYLOAD/Applications/$APP_NAME.app/Contents/Resources/hydra-inferno-bridge"
  codesign --force --options runtime --timestamp --deep --sign "$APP_SIGN_ID" "$PAYLOAD/Applications/$APP_NAME.app"
else
  log "Ad-hoc signing payload drivers and binary (Apple Silicon requirement)..."
  codesign --force -s - "$PAYLOAD/HAL/$DRIVER_NAME.driver"
  for drv in "$PAYLOAD"/HAL/HydraAudioBridge*.driver; do
    codesign --force -s - "$drv"
  done
  codesign --force -s - "$PAYLOAD/Applications/$APP_NAME.app/Contents/Resources/hydra-inferno-bridge"
fi

# ── 7. Compile SwiftUI Installer App ──────────────────────────────────────────
log "Compiling SwiftUI installer sources..."
SWIFT_FILES=("$PROJECT_DIR/Sources/HydraInstaller"/*.swift)
[[ ${#SWIFT_FILES[@]} -gt 0 ]] || fail "No .swift files found in Sources/HydraInstaller"

ARM_BIN="$BUILD_DIR/HydraInstaller.arm64"
X86_BIN="$BUILD_DIR/HydraInstaller.x86_64"

build_installer_for_arch() {
    local arch="$1"; local outBinary="$2"
    swiftc \
        -target "${arch}-apple-macos${MIN_MACOS}" \
        -O \
        -framework SwiftUI -framework AppKit -framework Foundation \
        -parse-as-library \
        -o "$outBinary" \
        "${SWIFT_FILES[@]}"
}

build_installer_for_arch arm64 "$ARM_BIN" || fail "Failed to compile arm64 installer binary"
if build_installer_for_arch x86_64 "$X86_BIN" 2>/dev/null; then
    log "Lipo-ing universal installer binary..."
    FINAL_BIN="$BUILD_DIR/HydraInstaller"
    lipo -create -output "$FINAL_BIN" "$ARM_BIN" "$X86_BIN"
    rm -f "$ARM_BIN" "$X86_BIN"
else
    log "x86_64 compile skipped. Producing arm64-only installer binary..."
    FINAL_BIN="$BUILD_DIR/HydraInstaller"
    mv "$ARM_BIN" "$FINAL_BIN"
fi

# ── 8. Assemble SwiftUI Installer App Bundle ──────────────────────────────────
log "Assembling installer app bundle..."
rm -rf "$STAGE_APP"
mkdir -p "$STAGE_APP/Contents/MacOS"
mkdir -p "$STAGE_APP/Contents/Resources"

mv "$FINAL_BIN" "$STAGE_APP/Contents/MacOS/HydraInstaller"
chmod +x "$STAGE_APP/Contents/MacOS/HydraInstaller"

# Copy Info.plist and update version properties
cp "$PKG_DIR/installer_resources/Info.plist" "$STAGE_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$STAGE_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$STAGE_APP/Contents/Info.plist"

# Copy resources
cp "$PROJECT_DIR/Backplane/Driver/Hydra.icns" "$STAGE_APP/Contents/Resources/AppIcon.icns"
cp "$PROJECT_DIR/LICENSE" "$STAGE_APP/Contents/Resources/LICENSE"
cp -R "$PAYLOAD" "$STAGE_APP/Contents/Resources/payload"

# PkgInfo
printf "APPL????" > "$STAGE_APP/Contents/PkgInfo"

# ── 9. Codesign Installer App ─────────────────────────────────────────────────
if [ -n "${APP_SIGN_ID:-}" ]; then
  log "Codesigning installer app with Developer ID: $APP_SIGN_ID"
  codesign --force --options runtime --timestamp --deep --sign "$APP_SIGN_ID" "$STAGE_APP"
else
  log "Ad-hoc signing installer app..."
  codesign --force --deep -s - "$STAGE_APP"
fi

xattr -dr com.apple.quarantine "$STAGE_APP" 2>/dev/null || true

# ── 10. Package into DMG ──────────────────────────────────────────────────────
log "Packaging installer into DMG..."
DMG_STAGE="$BUILD_DIR/dmg_stage"
rm -rf "$DMG_STAGE"
mkdir -p "$DMG_STAGE"
cp -R "$STAGE_APP" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

mkdir -p "$OUT_DIR"
DMG_PATH="$OUT_DIR/Hydra-$VERSION.dmg"
rm -f "$DMG_PATH"

hdiutil create \
    -volname "Hydra Installer" \
    -srcfolder "$DMG_STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

rm -rf "$DMG_STAGE"
log "Clean build artifacts..."
rm -rf "$PAYLOAD" "$STAGE_APP" "$BRIDGES_OUT" build/staging 2>/dev/null || true

log "DONE → $DMG_PATH"
