#!/bin/bash
# Hydra Audio — GPL-3.0
# Fetches the Steinberg VST3 SDK (GPLv3 option) into ThirdParty/vst3sdk.
# Only the hosting headers/sources are compiled (see Sources/HydraVST).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="$PROJECT_DIR/ThirdParty/vst3sdk"
SDK_TAG="${VST3SDK_TAG:-v3.7.9_build_61}"
SENTINEL="$SDK_DIR/.clone_complete"
LOCK_DIR="$PROJECT_DIR/ThirdParty/vst3sdk.lock"

log() { printf '\033[1;35m[vst3sdk]\033[0m %s\n' "$*"; }

# Ensure parent directory exists
mkdir -p "$PROJECT_DIR/ThirdParty"

# If the sentinel file exists, the clone is complete and we can exit immediately
if [[ -f "$SENTINEL" ]]; then
    log "VST3 SDK already present ($SDK_DIR)"
    exit 0
fi

# Acquire lock atomically using mkdir
log "Acquiring lock for fetching VST3 SDK..."
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    log "Another process is fetching VST3 SDK, waiting..."
    sleep 2
done

# Re-check sentinel in case another process finished while we waited
if [[ -f "$SENTINEL" ]]; then
    log "VST3 SDK was fetched by another process ($SDK_DIR)"
    rmdir "$LOCK_DIR"
    exit 0
fi

# Clean up any partial/failed clone to ensure a clean state
rm -rf "$SDK_DIR"

log "Cloning VST3 SDK @ $SDK_TAG (with submodules — this takes a minute) ..."
git clone --depth 1 --branch "$SDK_TAG" --recurse-submodules --shallow-submodules \
    https://github.com/steinbergmedia/vst3sdk.git "$SDK_DIR"

# Mark the clone as complete
touch "$SENTINEL"
log "Done: $SDK_DIR"

# Release lock
rmdir "$LOCK_DIR"
