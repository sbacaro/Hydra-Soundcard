# Packaging — Hydra `.pkg` installer

Builds a macOS installer that places **Hydra.app** in `/Applications` and **every
Hydra HAL driver** in `/Library/Audio/Plug-Ins/HAL` — the engine-hub driver
(`HydraVirtualSoundcard.driver`) plus all 8 Hydra Audio Bridge drivers
(`HydraAudioBridge{2A,2B,4,8,16,32,64,128}.driver`) — then reloads `coreaudiod`
so all the devices appear immediately. One install sets up everything; the user
never runs a script or installs a bridge by hand. The audio engine runs
in-process inside Hydra.app (no separate daemon / LaunchAgent).

```
Packaging/
├── build_pkg.sh        # builds the app + all HAL drivers and assembles the .pkg
├── distribution.xml    # installer UI / license / OS requirement
├── scripts/postinstall # root: fix ownership of every Hydra driver + restart coreaudiod
└── resources/          # welcome.html, conclusion.html
```

## Build

Requires Xcode and a generated project (`ruby Scripts/generate_xcodeproj.rb`).

```bash
bash Packaging/build_pkg.sh
# → dist/Hydra-<version>.pkg   (unsigned)
```

The output `.pkg` is written to `dist/` (git-ignored).

## Signed + notarized release (for distribution to other Macs)

An unsigned pkg installs fine locally, but Gatekeeper blocks it elsewhere. For a
public release you need an Apple Developer account and:

1. **Sign the app + driver** with a Developer ID Application certificate, and
   **sign the pkg** with a Developer ID Installer certificate — pass both as env
   vars to the build:

   ```bash
   APP_SIGN_ID="Developer ID Application: Your Name (TEAMID)" \
   INSTALLER_SIGN_ID="Developer ID Installer: Your Name (TEAMID)" \
   bash Packaging/build_pkg.sh
   ```

2. **Notarize** the resulting pkg and staple the ticket:

   ```bash
   xcrun notarytool submit dist/Hydra-<version>.pkg \
     --apple-id you@example.com --team-id TEAMID --password <app-specific-pwd> \
     --wait
   xcrun stapler staple dist/Hydra-<version>.pkg
   ```

3. Verify:

   ```bash
   spctl -a -vvv --type install dist/Hydra-<version>.pkg
   ```

Then attach the stapled `.pkg` to a GitHub Release (binaries are not committed to
the repo — see the root `.gitignore`).

## Notes

- The driver is a HAL plug-in (AudioServerPlugIn); SIP can stay enabled.
- The pkg requires macOS 26 (Tahoe) — enforced by `distribution.xml`.
- The app also carries the driver in its Resources as a fallback installer
  (first-run Welcome flow); when installed via this pkg the driver is already in
  place, so that step is skipped.
