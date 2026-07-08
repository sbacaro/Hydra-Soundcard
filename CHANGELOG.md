# Changelog

All notable changes to Hydra are documented here.

## [2.1.7] — 2026-07-08

### Fixed
- **Slave-Only Mode Enforcement**: Completely removed the `Preferred Leader` (`0x0022`) and `Enable Sync To External` (`0x0023`) parameters from the advertised capabilities configuration. This forces Dante Controller to display these fields as `N/A`, preventing Hydra from ever participating in clock leader elections and ensuring it remains a passive follower, identical to Audinate DVS.
- **Bonjour TXT Event-Driven Refresh**: Added delegate listener for Bonjour `didUpdateTXTRecord` to ensure clock ID metadata updates are parsed asynchronously as soon as the TXT data arrives from the network.

## [2.1.6] — 2026-07-08

### Fixed
- **Bonjour Binary Clock ID Resolution**: Fixed binary parsing of the mDNS service TXT records (`id` / `ID` fields) in `DanteClockBrowser`. Real Audinate hardware devices serialize the clock ID as raw 8-byte binary values (rather than ASCII hex strings) which previously resulted in a `nil` string parsing failure. Both binary and hex string serialization models are now supported natively.

## [2.1.5] — 2026-07-08

### Fixed
- **mDNS Clock Fallback**: Implemented a fallback mechanism utilizing an mDNS Bonjour browser to discover the network's active physical grandmaster clock ID from other Dante devices (like mixing consoles) when system sockets on ports 319/320 are locked by other running Dante tools. This establishes the proper Follower role in Dante Controller without disabling Audinate system services.
- **Unique DEVICE_ID**: Tweaked the generated PTP clock ID by incrementing the last byte of the MAC address to prevent clock ID collisions in Dante Controller when both Audinate DVS and Hydra run simultaneously on the same network interface.

## [2.1.4] — 2026-07-08

### Fixed
- **Audinate Daemons Conflict Resolution**: Added automatic unloading of conflicting Audinate background system services (`ConMon` and `DanteVirtualSoundcard`) to the installation helper script. This releases exclusive system locks on PTP ports 319/320 and control ports, enabling Hydra's PtpClock to bind, receive network sync packets, and report the correct Grandmaster Clock ID.

## [2.1.3] — 2026-07-08

### Fixed
- **Interface-Specific PTP Binding**: Resolved macOS wildcard routing restrictions by binding the daemon's PTP sockets directly to the active interface IP used by the Dante bridge rather than `0.0.0.0` (INADDR_ANY). This prevents Audinate's native clock services from overshadowing the sniffer, enabling reliable reception of network PTP packets and establishing correct master clock mapping.

## [2.1.2] — 2026-07-08

### Fixed
- **Clock Leader Conflict**: Corrected the clock synchronization architecture by dynamically scanning and writing the network PTP Grandmaster Clock ID to the device clock-stats files in `/tmp` when the PTP state changes. This informs Dante Controller that Hydra Soundcard is correctly following the leader (`Follower`) instead of advertising itself as a secondary leader, resolving the clock conflict ("AllenHeathSQ-7, Unknown Device*") and establishing channel subscriptions instantly.

## [2.1.1] — 2026-07-08

### Fixed
- **mDNS Goodbye Packets**: Emits instant TTL=0 multicast goodbye frames for all Dante and Inferno advertiser records upon Hydra shutdown. This instructs Dante Controller to clear the cached device immediately from its network list instead of displaying a greyed-out offline row.
- **Dante Diagnostics & Status**: Fully activated the mock parameter queries (opcodes `0x1100` and `0x1102`), allowing Dante Controller to successfully fetch clock sync leader status, network bandwidth (B/W) measurements, and latency statuses.
- **Dynamic Latency Reporting**: Serializes the user-selected Dante latency setting (e.g. 4 ms) into the diagnostics response payload instead of returning a hardcoded 1 ms value. This speeds up the connection handshake and transitions channel subscriptions from "Unresolved" to "Connected" instantly.

## [2.1.0] — 2026-07-08

### Added
- **Dante Status Indicator**: Integrated a dedicated Dante Virtual Soundcard status light in the application footer alongside Daemon, Backplane, and Engine. Displays a green checkmark when running and a clean, neutral grey circle when stopped.
- **Network Link Speed**: Replaced the redundant IP address text in the Dante configuration sidebar with the active network interface's real-time link speed (e.g. 1 Gbps, 10 Gbps, 100 Mbps).

### Changed
- **Window Size Constraints**: Synced window limits and enforced a minimum window size of 1080x660 points using native macOS content-size resizability. This prevents sidebar, matrix grid, and inspector panels from clipping or overlapping under any window configuration.
- **Off-Thread Network Queries**: Moved `ifconfig` link speed subprocess calls entirely off the main Swift thread into asynchronous background tasks, preventing UI freezes and lockups when refreshing network interface info.

### Fixed
- **Engine Startup Sincronization**: Fixed a critical bug where the Tokio broadcast receiver was early-dropped in the audio transmitter, resolving startup offline issues for the Engine and Backplane.
- **Rust Warning Cleanups**: Cleared all 72 compiler warnings (dead code, unused results/imports, lifetime issues) in the Dante Virtual Soundcard/Inferno crates for maximum performance and stability.

## [2.0.1] — 2026-07-07

### Fixed
- **Dante Subprocess Deployment**: Embed the precompiled universal bridge binary inside the app bundle, eliminating the runtime compile dependency on Rust/Cargo on end-user machines.
- **Auto-Interface Fallback**: Scan system interfaces at startup to dynamically bind Dante to the first active network interface with a valid IPv4 address, preventing initialization lockups when configured interface is absent.

## [2.0.0] — 2026-07-07

### Added
- **Dante Virtual Soundcard integration via Inferno.** Directly bridge Hydra Audio Bridges to the Dante network.
- **Auto-enable bridge integration.** Turning on Dante now automatically activates the selected Hydra Audio Bridge.
- **Experimental sub-toggles**. Configured checkboxes to individually enable/disable the "Control Surface" and "External Modules Host" views.

## [1.0.8] — 2026-06-29

### Capture
- **Flux — a new view for capture flows.** Alongside Grid and List, the toolbar now
  has a third view, **Flux**, for Audio-Hijack-style capture. A flow taps a device's
  **output** — whatever any app is playing to it — and routes it into Hydra,
  continuously, **without changing your system output**. Each flow is a signal-chain card you edit in place: choose the capture
  device and channels, pick where it lands. Selecting a flow opens its **Transmitter,
  Receiver and Connection** in the same channel-strip inspector as the grid, so
  inserts (plug-ins) and level work exactly as they do everywhere else. Flux stays
  separate from the channel grid — its routes don't show up in Grid/List, and
  switching views clears the inspector — because the two are different tools.

### Performance
- **Plug-ins load only when they're needed.** A channel's inserts used to spin up at
  launch whether or not anything was patched through them — loading heavy plug-in
  hosts (and briefly stressing the audio engine) for nothing. Now a strip instantiates
  its plug-ins only once a connection is routed through it, and a physical device's
  inserts wait until that device is actually present. Faster startup, less CPU, and no
  wasted hosts for an interface you've unplugged. (An unconnected plug-in already did
  zero audio processing; now it doesn't even load.)

## [1.0.7] — 2026-06-28

### Plug-ins
- **Inserts on the receiver side.** Plug-ins used to live only on the transmitter
  (source) side — audio was processed on its way out of a source. You can now also
  add inserts on the **receiver** (destination) side: everything patched into a
  destination is summed, run through that channel's inserts, then delivered to the
  receiving app or device. Open a destination channel (or select a patch cell) and
  the Receiver section now has its own Audio FX slots. The strip grid tags each card
  **TX** or **RX** so the two are easy to tell apart. Existing strips keep working
  unchanged — they default to the transmitter side.

### Refinements
- **Clearer Transmitter / Receiver split in the channel inspector.** The two ends of
  a patch are now separate tinted cards — a green **Transmitter** zone and an accent
  **Receiver** zone, each with a badged header, an accent stripe down its edge, and
  its own Audio FX. The patch's gain, signal and connect/remove controls moved into a
  dedicated **Connection** panel below both, so it's always obvious which side each
  control belongs to.

## [1.0.6] — 2026-06-26

### Plug-ins
- **One plug-in editor at a time.** Opening a plug-in's editor now closes the
  previous one, so windows don't pile up. Hold **⇧ Shift** while opening to pin a
  window — it stays put until you close it by hand, so you can keep a few side by
  side on purpose. (Works across crash-isolated hosts: the engine coordinates the
  windows wherever each plug-in is hosted.)

### Fixes
- **Soundcard device icon updated.** The Hydra audio devices still showed the old
  indigo waveform in Audio MIDI Setup and the sound menu — only the app icon had been
  switched to the Space Black mark. The driver's `Hydra.icns` (and its source iconset)
  are now regenerated from the new logo, so the devices match everywhere. (macOS caches
  device icons aggressively; a reboot may be needed for the new one to appear.)
- **Bridge direction control works again.** The Input / Output / Both segmented
  control in a bridge's inspector could look stuck — the highlight wouldn't move when
  tapped. It was bound straight to external state through a get/set closure, which
  the segmented control doesn't track reliably on macOS 26; it's now driven by local
  state and synced explicitly, so it responds immediately and the grid follows.

### Refinements
- **Notifications live in the bell now.** The floating toasts are gone — they never
  felt part of the app. Instead, a new event opens the event-bell popover (top-right)
  to show it, in the same place the full history already lived. Close the popover and
  you've silenced it: new events stop popping it open until you click the bell again.

## [1.0.5] — 2026-06-26

### Performance
- **Smooth plug-in list.** Settings ▸ Plugins stuttered when scrolling a large
  library fast. The list was re-filtering and re-sorting the whole library on every
  layout pass (and once more per row), with linear lookups for each plug-in's
  enabled/favorite state — O(n²). The filtered list is now computed once and cached,
  rebuilt only when a filter, the search or the library actually changes, with
  set-based lookups; rows scroll smoothly regardless of how many plug-ins you have.

### Refinements
- **Tidier notifications.** Toasts no longer pile up and cover the inspector. Repeats
  of the same message now coalesce into one with a count ("×3") and reset their timer
  instead of stacking; at most three show at once; they sit in the lower-left, out of
  the way of the channel strip and Connect button; warnings linger a little longer
  than routine status; and a click dismisses one. The full history still lives behind
  the bell.
- **Feedback loops are explained where you act.** Trying to make a patch that would
  howl now refuses it *inline* at the Connect button — the button tints to a warning,
  gives a small shake and shows the reason — instead of throwing a toast after the
  fact. The check runs in the app before anything is sent, so the patch is never even
  attempted.
- **Settings & About stay in front.** Both windows now float above the main Hydra
  window, so they no longer get buried behind it while you're using them.
- **Calmer sidebar icons.** The bridge and device glyphs were tinted bright blue and
  green; since almost everything listed is "present", the colour was decorative and
  inconsistent. They're now monochrome (like Audio MIDI Setup), with state carried by
  the bold name, the toggle and the tooltip — quieter and more consistent across the
  Devices, Apps and Network tabs.

## [1.0.4] — 2026-06-26

### Fixes
- **Auto-update now installs.** Every build through 1.0.3 aborted the install step
  with *"Update failed — an identifier can't go after this number."* The installer
  command was embedded in an AppleScript string without escaping the quotes around
  the package path, so the script broke apart and the temp-folder path was parsed
  as code (AppleScript error -2740). The whole command is now properly escaped, so
  the password prompt appears and the update installs and relaunches as intended.

> Note: because the bug lived in the updater itself, upgrading **to** 1.0.4 must be
> done once by hand (download the installer from the Releases page and run it).
> Automatic updates work normally from 1.0.4 onward.

## [1.0.3] — 2026-06-25

### Polish & fixes
- **Window-at-launch.** Opening Hydra from Finder/Applications/Spotlight now opens
  its window; starting at login still stays in the menu bar (no window).
- **No more clipped text.** Sidebar descriptions and the ⓘ info popovers wrap to
  show the whole sentence, and truncated names reveal their full text on hover.
- **The CPU meter colour now tracks load**, not XRUNs: grey below 50%, amber from
  50%, red from 75% (the XRUN count stays in the tooltip).
- Fixed the menu-bar waveform glyph rendering upside down.

## [1.0.2] — 2026-06-25

### Brand & appearance
- **New Hydra logo** — a clean waveform on an Apple "Space Black" gradient (a deep
  near-black charcoal with a subtle warm sheen). The app icon, the plugin-host
  icon, every in-app mark and the menu-bar glyph now share this one design, all
  served from a single source (`IconPack`) so the look changes in one place.
- **Follows the macOS accent.** With the brand mark now neutral, the UI tint is
  the accent the user chose in System Settings instead of a hard-coded indigo —
  and the patch grid, selections and toggles are finally all consistent.

### Launch behaviour
- **Opening Hydra from Finder/Applications/Spotlight now opens its window** (it had
  been launching to just the menu bar). **Starting at login still stays in the
  menu bar** (no window) — the two are told apart by the login-item launch event.

## [1.0.1] — 2026-06-25

### Fixed
- **Plugin editor window now opens.** The out-of-process plugin host ran as a
  faceless (accessory) app, and some VST3 editors crash when their view is
  created without a foreground app — so the editor never appeared (the plugin
  was bypassed by crash protection). The host now becomes a regular foreground
  app **while an editor is open** — the window opens reliably, like any normal
  app window — and returns to faceless when the last editor closes, so there is
  still no persistent Dock icon. With Crash Protection turned off, the plugin
  runs in-process and its editor is a normal Hydra window, just like Settings.
- **Plugins now load in the signed release build.** The out-of-process plugin
  host had the hardened runtime enabled but no entitlements, so library
  validation blocked third-party VST3 `.dylib`s — plugins (and their editors)
  worked from a local Xcode build but not from the installed `.pkg`. The host now
  carries its own `disable-library-validation` + `allow-unsigned-executable-memory`
  entitlements (matching the main app), so plugins load from the release.

### Auto-update — hardened
- The update check no longer collapses every failure into "Could not reach the
  update server": it now distinguishes **no release yet** (404, treated as up to
  date), **rate-limiting** (403/429, with a clear "try again later" message) and
  other HTTP errors (shown with their status code), so a failed check is
  self-diagnosing.
- Checks now **bypass the URL cache** and use a timeout, so a 404 cached before a
  release was published can never hide a release published later.
- **Automatic** (launch) checks are throttled to once every 6 hours, so frequent
  relaunches don't burn GitHub's unauthenticated rate limit (60/h per IP). A
  manual "Check for Updates" still runs immediately.

## [1.0.0] — 2026-06-25

First stable release. Hydra is now a single app process, ships eight selectable
audio devices instead of one, and is fully localized in five languages.

### One process
- **The audio engine runs in-process.** The former standalone `hydrad` daemon +
  LaunchAgent is gone; the engine is a framework (`HydraDaemon`) started inside
  the app, talking to the UI over a local WebSocket. The Dock and Activity
  Monitor now show **one** Hydra process, not two.

### Eight Hydra Audio Bridges (replaces the single virtual soundcard)
- The single 256-channel "Hydra Virtual Soundcard" is replaced by **eight fixed,
  independently selectable loopback devices** — Hydra Audio Bridge 2-A, 2-B, 4,
  8, 16, 32, 64 and 128 (N in / N out each). Any app can pick a bridge as its
  input or output, Loopback-style; toggle each on/off in the sidebar.
- A hidden **"Hydra Engine"** hub drives the routing matrix; the engine attaches
  a bridge's audio path **lazily** (only when it's actually patched), and a
  debounce coalesces device-toggle storms so coreaudiod stays stable.
- Per-bridge **NDI / AES67 transmit** can be enabled independently.
- Bridges, physical interfaces, captured apps and network sources all patch in
  one unified matrix.

### Performance
- **Unity fast-path in the ASRC.** When producer and consumer share the sample
  rate (all bridges + hub at 48 kHz), the ring uses linear interpolation instead
  of the polyphase sinc — ~10× less CPU per channel, transparent at unity.
- Unconnected channel strips do **zero** plugin work, and unpatched bridges open
  no IO proc — engine load scales with what's actually routed.

### Plugins (VST3)
- An insert now processes audio **only when its source is patched** somewhere —
  no more a plugin "hearing" an unrouted source.
- Adding an insert **opens its editor automatically**, and the out-of-process
  plugin host no longer shows a **Dock icon** (stays an accessory app; App Nap is
  held off so editors stay live).
- Plug-in search is **fuzzy and order-independent** ("proq fab" finds
  "FabFilter Pro-Q").

### UI — Apple HIG
- **Patch grid:** a single click toggles a connection (⌘-click selects for gain
  editing); Numbers-style zebra rows, accent crosshair and circular connection
  dots.
- **Device View** (mass patch): channel rows drop the redundant device name,
  aligned columns, calm empty states.
- **Network tab** rebuilt — PTP "no grandmaster" is a quiet status footer, not a
  warning; empty AES67/NDI states are calm centered placeholders.
- Sidebar master/detail with a per-bridge inspector; minimalist menu bar; the
  main window reopens on relaunch and on Dock click.
- **Source signal pins** now light from the source's own audio, even with no
  patch made.

### Localization — five languages
- Complete **Brazilian Portuguese**, plus brand-new **Spanish, French, German and
  Italian** — the full UI (Settings, About, sidebar, grid, onboarding) across all
  368 strings. Fixed several strings that bypassed localization (String-typed
  helpers) and refreshed copy that still referenced the old single soundcard.

### Build
- Run Script sandboxing enabled (Xcode's recommended setting); the VST3-SDK fetch
  is isolated to a `FetchVST3SDK` aggregate target so the "Copy Headers delayed"
  warning is gone. Project baseline bumped (no more "update to recommended
  settings" nag).

## [0.21.0 beta] — 2026-06-21

### Auto-update — self-contained, no third-party framework
- **Removed Sparkle.** The in-app updater is now a small built-in component
  (`Updater.swift`, system frameworks only): it polls the latest GitHub Release,
  downloads the `.pkg`, **verifies it against a published SHA-256 checksum**, and
  installs it via a single macOS admin prompt, then relaunches. App and audio
  driver update together. No appcast, no embedded framework, no EdDSA key to
  manage.

### Audio quality
- **Polyphase resampler.** Replaced the ASRC ring's 2-tap linear interpolation
  with a Kaiser-windowed-sinc polyphase kernel (`PolyphaseResampler`), built once
  per clock ratio. It **anti-aliases on decimation** (cutoff lowered for ratio
  > 1) — a real quality step up for cross-clock device routing (e.g. 96 ↔ 44.1k).

### Real-time DSP as a testable library (HydraRT)
- Extracted `ChannelRing` (SPSC ring + resampler) and the AudioBufferList helpers
  out of the daemon into a new **`HydraRT`** framework, so the real-time path is
  unit-testable on its own.

### Testing & CI
- Greatly expanded coverage: exhaustive `HydraCore` parser/model tests, polyphase
  resampler tests, and a **concurrent producer/consumer ring stress test**.
- **Sanitizers in CI:** the suite (incl. the ring) runs under AddressSanitizer +
  UBSan and ThreadSanitizer.
- **SwiftPM parity:** `swift test` now builds `HydraCore`/`HydraRT` in Swift 6
  language mode with complete strict-concurrency checking, matching the Xcode build.

### Observability
- **MetricKit** integration (`MetricsReporter`): crash / hang / CPU-exception /
  performance payloads are captured locally and listed in the diagnostics export
  — no third-party telemetry. Logging standardized on `os.Logger`.

### UI — Apple HIG polish
- Search fields now use the native macOS search control (magnifying glass + clear
  button + reliable focus) via a reusable `SearchField` — fixes the plug-in search
  that only focused on the text glyph. Reusable `Badge` for type/status pills.
- Patch grid: continuous (squircle) corners and **Dynamic Type** support.
- Device-view list now shows an app's name (e.g. "Safari") instead of its raw
  node id.

### Build & security
- **Build migrated to XcodeGen** (`project.yml`); the Ruby generator is kept as a
  fallback.
- Update trust model documented (`SECURITY.md`): SHA-256 + repository control.
  CI runs least-privilege, the release workflow is gated to the canonical repo,
  and GitHub Actions are pinned to commit SHAs.
- Repository moved to `github.com/sbacaro/Hydra-Soundcard`.

## [0.20.0 beta] — 2026-06-20

### Modernization & Swift 6 Native Concurrency
- **Native Mutex Migration**: Replaced C-style `NSLock` locks with Swift 6 native `Synchronization.Mutex` in `ModuleManager` and `PtpClock` to ensure safety and compiler-enforced thread-safety.
- **Adaptive IPC Loop**: Rewrote the out-of-process VST host audio thread loop (`runAudioLoop`) in `hydra-plugin-host` with adaptive sleeping. Thread sleeps when idle, bringing CPU usage down to 0% when no audio is routed.
- **Real-Time Priority VST Host**: Promoted the out-of-process VST host thread to real-time priority using Mach `THREAD_TIME_CONSTRAINT_POLICY` to eliminate audio clicks under load.
- **Synchronized Thread Teardown**: Introduced DispatchSemaphores (`threadExitSemaphore`) in `NdiManager` (RX/TX) and `Aes67Tx` to block thread deallocation until processing terminates, eliminating crash-on-close segmentation faults.

### Performance & UI Refinements
- **O(1) Grid Routing Lookup**: Extracted grid connection indexer into a reusable `ConnectionIndex` struct, optimizing routing lookups from $O(N)$ linear scans to $O(1)$ fast dictionary lookups.
- **Settings UI Polish**:
  - Restyled the available VST3 plug-ins view as a native list box with background and border.
  - Added a search bar with a background card and icon.
  - Integrated `ContentUnavailableView` for empty states when VST search has no results.
  - Added a rounded border to the OSC UDP port field.
- **Startup Stability**: Added static session checking in `InstallManager` to prevent driver refresh/reinstallation loops at launch.

## [0.15.1 beta] — 2026-06-04

### Performance (user report: HydraApp at 100% CPU)
- **The grid no longer observes the 10 Hz meters.** Signal LEDs are now tiny
  leaf views (SignalDot) — meter ticks re-render four-pixel dots instead of
  rebuilding the entire grid (groups + Canvas) up to ten times a second.
- **Cell lookups are a Set, not a filter**: the Canvas used to scan the
  connection array per cell per repaint (O(cells × connections) on every
  hover move); now it's one Set built per pass, O(1) per cell.
- **The daemon skips identical meter broadcasts**: an idle system sends
  nothing — no JSON encoding, no app wake-ups. Real audio changes every
  tick, so meters lose nothing.

## [0.15.0 beta] — 2026-06-04

### Changed — grid clarity, Hydra style (user direction)
- **Device bars** on both axes, like Dante Controller but in our language:
  the device/interface name lives in a solid rounded bar (icon + name),
  channels indent beneath it. Column device names are fully vertical (90°)
  inside their bars — no more diagonal overflow or truncated headers.
- **Visible lattice**: every cell shows a hairline edge, so the field reads
  as a patch matrix even when empty; thin separator lines mark where one
  device ends and the next begins (lines, not bands — cells stay cells).
- Channel column labels rotated to vertical as well; crosshair highlight
  slightly stronger.
- Grid panel clips with its rounded shape (nothing can draw outside the
  square); Channel panel is now a matching card with the same vertical span
  as the grid square.

## [0.14.4 beta] — 2026-06-04

### Changed (user feedback)
- Channel panel type raised to the app ramp (labels 13 pt, title 14 pt) —
  no more shrunken side panel.
- "Remove N patches" pill calmed down: neutral colors, fixed label
  "Remove patch" (count lives in the tooltip), ⌫ still works.

### Changed (user feedback — device clarity, Dante Controller style)
- **Every group now says what it IS**: a kind icon on row labels, column
  headers and list sections — virtual interface, app capture (e.g. Safari),
  audio interface, AES67 stream, NDI source — with the kind spelled out in
  the tooltip.
- (Reverted in the same build: cell-field zebra/bands made collapsed group
  columns look like dead cells and squeezed the rotated headers — the
  original cell design is back. Device kind lives in the row icons and
  tooltips only.)

## [0.14.3 beta] — 2026-06-04

### Added (user request — Dante Controller workflow)
- **Batch patching in list view**: in the source picker, ⇧-click selects a
  contiguous range of transmitter channels (⌘-click toggles single ones);
  "Patch N channels" assigns them to consecutive receiver channels starting
  at the clicked row — bounded by the receiver's interface/device, exactly
  like assigning a multichannel device in Dante Controller's Device View.
  A plain click still patches one source instantly.

## [0.14.2 beta] — 2026-06-04

### Fixed
- **Trackpad scroll in the grid**: the inner pane was sized by its content
  (a 128-row label stack), so the cell ScrollView thought everything was
  visible and had nothing to scroll. The pane is now hard-bounded to the
  viewport; two-finger scrolling pans the cell field with frozen headers.

### Changed (user request — Dante Controller convention)
- **Transmitters on top, receivers on the left**: sources (interface Ins,
  captured apps, NDI/AES67 streams, device inputs) are now the COLUMNS;
  destinations (interface Outs, device outputs) are the ROWS. Corner reads
  RX ▼ · TX ▶; signal LEDs, crosshair, selection and double-click follow.

## [0.14.1 beta] — 2026-06-04

### Fixed
- Big interfaces (e.g. 128×2) no longer blow up the window layout: the grid
  pane is pinned to the top-left of its area and the channels scroll INSIDE
  it with frozen headers, as designed.

### Changed (user request)
- **"Groups" toggle** above the grid: ON = channels banked in collapsible
  groups of 8 (collapsed by default, "Collapse all" available) — the right
  mode for 64/128-channel interfaces; OFF (default) = flat list, one header
  per node. Preference persists.

## [0.14.0 beta] — 2026-06-04

### Added — AES67 TX (Phase 5, first slice; user request)
- **A virtual interface can be announced on the network**: the AES67 toggle
  (on the interface row, or at creation — the AES67 template ships with it
  ON) announces the Out side via SAP/SDP and transmits multicast RTP
  (L24, 1 ms packets, 239.69.x.y:5004, up to 8 channels per flow). It
  appears in Dante Controller as an AES67 flow. EXPERIMENTAL: no PTP sync
  yet, so strict receivers may refuse to lock — that's the remainder of
  Phase 5.

### Changed — Network tab is now a real network view
- NDI sources show format (channels @ rate) and address; AES67 device notes
  shortened to status.
- New "Hydra on the network" section: every flow Hydra is transmitting
  (AES67 with group:port, NDI) with live status.
- Instructional texts moved into clickable ⓘ balloons (Apple style) —
  headers stay clean, the help is one click away.

## [0.13.1 beta] — 2026-06-04

### Changed (user feedback)
- **Type scale raised ~2 pt across the app** to match the macOS system ramp
  (body 13 pt): channel labels 11→13, lists 12–13, status bar 13, notes 11,
  micro-labels 10 minimum. Grid metrics follow (rows/cells 30 pt, label
  column 150 pt, header 72 pt); top/status bars and the channel panel got
  proportionally taller/wider.
- ⌥-click on the gain fader snaps it to 0 dB (Logic behavior).
- Strip-path diagnostics in the daemon log (in/out dBFS per chain, rerouted
  connection counts) to pinpoint the "EQ changes are inaudible" report.

## [0.13.0 beta] — 2026-06-04

### Changed — Settings restyled (user feedback)
- Settings (⌘,) now follows the app: Logic Pro-style preferences with icon
  tabs in the toolbar (General / Audio / Control), dark theme, same accent.

### Changed — interface creation (user feedback)
- **Type-first creation**: pick a template (Custom, DAW, OBS, AES67, NDI)
  and the form pre-fills name, channel counts and NDI TX — everything still
  editable. No more blank-page moment.
- **Independent In × Out sizing**: an interface now has separate input and
  output channel counts (e.g. an AES67 return of 128 in × 2 out). Each side
  gets its own exclusive slice of the 256-channel pool — slices never alias
  across directions, so the driver loopback can't create hidden couplings.
  NDI TX and recording use the Out side. Old interfaces.json files load
  unchanged (legacy = same size both ways).

## [0.12.1 beta] — 2026-06-04

### Added (user requests)
- **Multi-selection + ⌫**: ⌘/⇧-click selects several cells in the grid;
  the control bar shows "Remove N patches" and the Delete key (⌫) removes
  every patched connection in the selection.
- **List patching** (Dante Controller Device-View style): a Grid/List
  toggle above the grid. List mode shows every destination channel as a
  row — current sources appear as chips (✕ removes; click selects for the
  channel strip) and "+" opens a searchable source picker.

## [0.12.0 beta] — 2026-06-04

### Added
- **OSC remote control** (Settings → Control, off by default): UDP server in
  the daemon for consoles, TouchOSC and Stream Deck via Companion.
  Addresses: `/hydra/scene/apply` (name or index), `/hydra/scene/save`,
  `/hydra/record/start`, `/hydra/record/stop` (interface name). OSC 1.0
  parser in HydraCore, unit-tested (messages + bundles).
- **Recording**: the record button on a virtual interface captures whatever
  is routed to its Out channels into a WAV (float32, engine rate) in
  Music → Hydra Recordings. Engine side reuses the NDI TX slice-copy path.
  Deleting an interface stops its recording.
- **About / legal overhaul** (GPL §5d Appropriate Legal Notices): license
  statement + warranty disclaimer, GPL full-text and source-code links,
  credits with trademark notices — BlackHole (GPL-3.0), Steinberg VST 3 SDK
  (GPLv3 option, VST® trademark), NDI® (Vizrt trademark, runtime never
  bundled), AES67/OSC as from-scratch open standards, Dante®/Audinate
  non-affiliation. THIRD_PARTY_NOTICES.md updated to match.

### Changed (by user feedback)
- **Status moved to the bottom bar**: the top bar keeps only the brand and
  the event bell; daemon/backplane/engine now live in the status bar with
  the connection/rate readout — one type size (11 pt), consistent casing,
  no more duplicated info in two places.
- Channel panel slimmed (270 → 248 pt) so the grid keeps visual priority.
- **Grid collapse removed** — it got in the way. All channels are always
  visible; group labels remain as static section headers. The virtual
  interface model keeps the channel set small, so collapsing lost its
  purpose. "Clear visible" now means everything shown in the grid.

### Fixed
- Settings toggles now mutate a config copy — changing one option no longer
  resets the others.
- Hydra's internal tap aggregates ("Hydra Tap (Safari)") no longer leak into
  the Devices list — internal plumbing is filtered by UID prefix.

## [0.11.0 beta] — 2026-06-04

### Added — NDI RX + TX (user decision: real NDI, now)
- **NDI receive**: sources on the network appear in the sidebar (Network →
  NDI sources); subscribing adds their channels to the grid as inputs.
  Format (channels/rate) is learned from the first audio frame — the source
  joins the engine only then, through the same ring + ASRC path as AES67.
- **NDI transmit**: any virtual interface can broadcast — toggle the antenna
  on its row (or at creation). Whatever you route to the interface's Out
  channels goes out as an NDI audio source named after it. Engine side: a
  post-mix copy of the interface's pool slice feeds a sender thread.
- **Licensing (GPL-safe, DistroAV pattern)**: the proprietary NDI runtime is
  never bundled or linked. HydraNDIShim (new C target) dlopen()s the runtime
  installed from Vizrt's official redistributable; `vm_install.sh` now
  downloads/installs it automatically from the official link. Without it,
  the app shows "runtime not installed" + a download link, and everything
  else keeps working.
- Naming an interface "NDI 6" in 0.10.0 was organizational — now it's real.

## [0.10.0 beta] — 2026-06-04

### Added — Virtual interfaces (user proposal)
- **The app starts with zero channels; you build your own set.** The raw
  256-channel pool is now invisible. You create named virtual interfaces
  (e.g. "AES67 Stage 32", "OBS 2") and each one allocates a contiguous
  slice of the pool — only those channels appear in the grid.
- Create via the "+ Interface" button above the grid or in the sidebar
  (Devices → Virtual interfaces); 1–64 channels each, daemon allocates and
  persists (interfaces.json). Deleting frees the slice and removes its
  patches. Pool usage indicator (n / 256).
- Empty grid shows an onboarding hint instead of hundreds of unused lanes.
- The Settings "channels shown in the grid" picker is gone — superseded by
  this model. Naming an interface "NDI 6" is organizational for now: NDI
  transport itself remains a future extension.

## [0.9.3 beta] — 2026-06-04

### Changed (by user feedback)
- **One font everywhere**: SF Pro across the whole UI; numbers use
  monospaced DIGITS only (alignment without changing typeface).
- **All channels are MONO** — the stereo lane option is disabled (it had
  routing bugs); apps appear as two mono lanes (L/R). The strip lost the
  Mono/Stereo toggle.
- **Pagination replaced by collapsible groups of 8** (user proposal): the
  whole system is visible at once as group headers; expand only where you
  work. Headers stay frozen to the top-left like Dante Controller; the cell
  field is a single Canvas, so even fully expanded it stays fast.
  "Clear visible" now acts on the expanded channels.
- Grid is anchored to the top-left corner of its area.
- Settings gained **App capture → makeup gain** (0–24 dB, daemon-side,
  persisted): the calibration for quiet app captures now lives in the UI.

## [0.9.2 beta] — 2026-06-04

### Added (by user feedback)
- **Settings window (⌘,)**: choose how many Hydra Soundcard channels appear
  in the grid (16–256; the driver keeps 256, patches outside the range keep
  working) and toggle **Feedback protection** (daemon-side, persisted).
- **Clear page** button: removes every connection in the visible 16×16 block
  only, with confirmation.
- **Resizable sidebar**: drag the divider (180–380 px) — long names stop
  truncating.

### Changed
- Plugins tab removed from the sidebar (plugins are picked in the channel
  strip's Insert slot, where they belong).
- Trackpad feedback now ticks continuously while dragging the gain fader,
  with the stronger detent kept at 0 dB.
- Brand area: bigger mark + "Hydra Soundcard" title.
- Grid pagers renamed to "INPUTS (ROWS)" / "OUTPUTS (COLUMNS)" with clearer
  tooltips; channel labels got ~50% more room.

## [0.9.1 beta] — 2026-06-04

### Added (by user feedback)
- **Feedback protection**: the engine rejects connections that would create a
  loop on the loopback backplane (including In n → Out n and indirect cycles
  through other connections), and skips them when applying scenes — with a
  warning explaining why.
- **Events & alerts**: the daemon now emits user-relevant events — feedback
  blocked, device disconnected/re-bound, app-capture permission failures,
  plugin load failures. They appear as discreet transient **toasts**
  (top-right, 5 s) and stay in the **bell menu** in the top bar (last 50,
  with timestamps; the bell shows a badge while warnings/errors are present).
- **Device View in the sidebar**: lists now show only what matters
  (status dot, name, toggle); clicking an item opens its full specifications
  (channels, sample rate, UID, bundle ID, multicast address…) with the
  action toggle — Dante Controller style.

### Changed
- **Grid: double-click to assign / double-click to remove.** Single click
  now only selects the cell (opens the channel strip) — no more accidental
  patches while inspecting.

## [0.9.0 beta] — 2026-06-04

### Changed (final redesign — based on the user's approved Figma prototype)
- **New shell**: deep blue-black gradient with subtle ambient glows, custom
  top bar (the brand mark keeps its indigo gradient — the rest of the UI uses
  Apple system blue), status pills with real daemon/backplane/engine state,
  and a bottom status bar (real data only: connections, sample rate, format).
- **Sidebar with tabs** (Devices / Apps / Network / Plugins) replaces the
  popovers; every section has an ⓘ hover explanation, every tool a tooltip.
- **Paginated grid, 16×16 lanes per page** — the fix for big channel counts:
  the grid is fixed-size (headers frozen by construction, like Dante
  Controller) and at most 256 cells exist at once, so 256×256 can never slow
  the UI. Per-axis pagers with a jump-to-device/app menu. Cells in the
  prototype's style: glowing blue squares, ghost hover outline, row/column
  crosshair. Click toggles the subscription; ⌥-click inspects.
- **Logic Pro-style VU meter** in the channel strip: vertical segmented LED
  bars — two bars when the cell is a stereo group — with peak-hold lines and
  click-to-reset clip LEDs.
- **Trackpad haptics on the gain fader**: Logic-style detent pulse when
  crossing 0 dB (NSHapticFeedbackManager).
- Still pending from this spec: list-style channel assignment (Dante Device
  View mode), CPU/XRUN metrics in the status bar (daemon support first —
  no fake numbers), ⌘K palette.

## [0.8.2 beta] — 2026-06-04

### Changed (mono/stereo is now real — by user feedback)
- **Stereo lanes in the grid**: toggling Stereo on the channel strip collapses
  the pair into ONE row and ONE column ("In 1-2" / "Out 1-2"); captured apps
  are a single lane named after the app. One click patches the whole lane
  with console rules: stereo→stereo = L→L/R→R · stereo→mono = both summed ·
  mono→stereo = duplicated (badge in the strip shows which rule applied).
- Cell gain and meter operate the channel group (meter shows the pair's max);
  removing a cell removes all its underlying connections.
- Engine unchanged — connections stay per-channel under the hood, so scenes
  and persistence keep working.

## [0.8.1 beta] — 2026-06-04

### Changed (by user feedback)
- **Trim removed from the channel strip** — redundant with the per-connection
  Gain, which is the foundational model ("every connection carries a gain").
  One level control per view: the strip handles inserts; the output section
  handles level. (The protocol field remains, defaulting to unity.)

## [0.8.0 beta] — 2026-06-04

### Changed (Logic-style channel strips — UI milestone, part 1)
- **The side panel is now a DAW channel strip** for the selected source,
  top-to-bottom: input (name + **Mono/Stereo** toggle; apps are stereo by
  default and locked), **Audio FX insert slots** (click an empty slot to
  search plugins by name; click a loaded slot to open its editor; ✕ removes),
  channel **Trim** (±24 dB, pre-inserts), then the output section for the
  selected connection (gain, dBFS meter, remove).
- **Inserts live on the channel now** (Logic semantics): everything leaving
  that source passes through its inserts before reaching any destination.
  Stereo strips process the L/R pair together in the same plugin instances.
- **"Chains" are gone** from the UI and protocol (VST popover removed; the
  per-connection Insert picker removed). Strips persist (`strips.json`) and
  re-bind by node+channel. Protocol: `strips`/`setStrip`;
  `openPluginEditor` now takes (stripID, slot index).

## [0.7.2 beta] — 2026-06-04

### Added
- **Plugin editor windows**: click a plugin's name in the VST popover to open
  its real GUI. Parameter changes flow from the editor to the audio thread
  through a lock-free queue, so tweaks are audible live. Implementation:
  EditController instantiation + component↔controller connection + state sync,
  IPlugView hosted in an NSWindow inside the daemon (which now runs an
  accessory NSApplication loop so editors receive input). Closing the window
  hides it; reopening refocuses it.

### Coming next (Logic-style mixer milestone)
- The "chains" concept will dissolve into per-channel insert slots
  (mono/stereo channels, searchable plugin picker, side panel as a DAW
  channel strip with top-to-bottom signal flow) — design agreed, in progress.

## [0.7.1 beta] — 2026-06-04

### Changed (by user feedback)
- **VST chains are now console-style inserts, not grid channels.** Select an
  existing connection and pick the chain under **Insert** in the Inspector —
  the connection's audio passes through the chain (even source channels → L,
  odd → R; the meter reads post-insert). No more separate chain rows/columns
  in the grid. The VST popover remains the chain library (create/delete
  chains, add/remove plugins).
Format: [Keep a Changelog](https://keepachangelog.com). Versioning: `major.minor.patch` + stage.

## [0.7.0 beta] — 2026-06-04

### Added (Phase 6 — VST3 in the signal path)
- **VST3 effect chains as grid nodes**: create a chain in the new **VST**
  popover, add plugins from `/Library/Audio/Plug-Ins/VST3` (system + user),
  then patch any source → chain input (→name) and chain output (name→) →
  any destination. Empty chains pass audio through.
- **Engine**: chains process INSIDE the engine callback (same clock domain —
  no rings, no added latency) with two-pass mixing: sources → chain inputs,
  chains render, chain outputs → destinations. v1: stereo chains, no
  chain→chain patching, plugins at default state (editor GUI ships with the
  UI-redesign milestone).
- **HydraVST**: new C++ target hosting the Steinberg **VST3 SDK (GPLv3
  option)**, fetched at build time by `Scripts/fetch_vst3sdk.sh` into
  `ThirdParty/`; pure-C surface so Swift stays clean. Notices updated.
- Protocol: `getVST` / `vst` / `createChain` / `deleteChain` / `addPlugin` /
  `removePlugin`; chains persist (`vstchains.json`).

## [0.6.0 beta] — 2026-06-04

### Added (Phase 4 — AES67 reception, "the Controller")
- **Network discovery** (Section 5.5): passive mDNS browsing of Dante
  `_netaudio-*` services (presence) + SAP listener on 239.255.255.255:9875
  parsing SDP (available streams). Cross-referenced badges per device:
  **AES67 On** (announcing, subscribable) / **AES67 Offline** (present, enable
  AES67 in Dante Controller).
- **Stream subscription (RX)**: subscribing joins the stream's multicast
  group, parses RTP (L24/L16 big-endian → Float32) and feeds the engine
  through the same ring/ASRC path as physical devices — no PTP needed for
  reception. Subscribed channels appear as grid sources.
- **New "Network" popover** with devices, badges and stream toggles;
  subscriptions persist (`aes67.json`) and re-bind when streams re-announce.
- SAP/SDP parsers are pure functions in HydraCore with unit tests (runnable
  without Dante hardware).
- **Field testing pending** — requires a Dante device with AES67 enabled and
  bridged VM networking; full checklist in the README.

## [0.5.7 beta] — 2026-06-04

### Changed (driver V5 — the app is the only control surface)
- **Hydra device icon**: the backplane now ships with the Hydra logo
  (indigo waveform; `Backplane/HydraIcon.iconset` packed at build time).
- **Zero editable controls in Audio MIDI Setup**: clock source and pitch
  controls unpublished (volume/mute already were), and the device exposes a
  **single fixed sample rate (48 kHz)** — the format dropdown has one option.
  Everything about the backplane is controlled from the Hydra app only.
  Requires reinstalling the driver.

## [0.5.6 beta] — 2026-06-04

### Changed
- **System volume slider fully locked for the backplane**: the driver no
  longer publishes ANY volume/mute controls (entries removed from its object
  lists), so macOS greys the slider out — the user cannot even try to attenuate
  or mute the backplane. Mute-setter neutralization kept as belt-and-suspenders.
  Requires reinstalling the driver.
- **App-tap makeup raised to +12 dB** (`Hydra.appTapMakeupDB`, single
  calibration constant): the tap mixdown attenuation is undocumented and the
  Inspector meter isn't trusted for calibration yet, so this is an approximate
  value — adjust in one place if captures still don't match interface levels.

## [0.5.5 beta] — 2026-06-04

### Fixed
- **Mute locked off**: with volume control gone (0.5.4), the system slider at
  zero still engaged the driver's mute control and cut the loopback. The mute
  setter is now neutralized in the driver build — the backplane is fully
  immune to macOS volume/mute. Requires reinstalling the driver.

## [0.5.4 beta] — 2026-06-04

### Changed
- **Backplane is now bit-perfect**: the driver is built with volume control
  disabled (`kEnableVolumeControl=false`), so the system volume slider can no
  longer attenuate audio entering the grid. Level control belongs to the
  per-connection gain. Requires reinstalling the driver
  (`host_build.sh` re-clones BlackHole and applies the V2 overrides
  automatically).

## [0.5.3 beta] — 2026-06-04

### Fixed
- **App capture level, take two.** Field testing showed tap level does NOT
  follow the output volume knob (the driver applies volume after the tap
  point), so 0.5.1's dynamic volume compensation inverted the problem and was
  removed. The real cause of quiet captures is the tap's stereo-mixdown
  pan-law attenuation: app taps now get a fixed **+6 dB makeup**, matching
  soundcard-routing levels at any system volume.

## [0.5.2 beta] — 2026-06-04

### Fixed
- **Apps show their commercial identity**: processes are attributed to their
  responsible app (macOS responsibility lookup) — "Safari Graphics and Media
  (com.apple.WebKit.GPU)" becomes **Safari**, Chrome helpers become
  **Google Chrome**. Helper-suffix stripping fixed and kept as fallback.
- Note: apps captured under helper identities in 0.5.x need re-enabling once
  (the persisted ID changed to the responsible app's bundle ID).

## [0.5.1 beta] — 2026-06-04

### Fixed
- **One grid node per app**: browser helper processes (e.g. Chrome's) share a
  bundle-ID variant and showed up as duplicate, mirrored rows. Processes are
  now grouped under a canonical bundle ID (".helper…" stripped); the tap mixes
  all of the app's processes and is rebuilt transparently when helpers
  spawn/die.
- **Capture level no longer follows the system volume knob**: process taps are
  post-output-volume, so captures came in quiet. The daemon now watches the
  default output device's volume and applies the inverse (makeup clamped at
  +30 dB) to every app tap — captured level stays constant.

## [0.5.0 beta] — 2026-06-04

### Added (Phase 3 — Per-app capture, process taps)
- **Capture any app's audio** without touching its output device: the new
  **Apps** popover lists audio-capable apps (live "playing" indicator);
  toggling capture makes the app a **stereo source** in the grid (L/R rows).
- Implementation: Core Audio **process tap** (macOS 14.4+ API) → private
  drift-compensated aggregate device → IOProc → the same ring/ASRC path used
  by physical devices (engine taps generalized to a common protocol).
- **Identity & re-bind**: captured apps persist by bundle ID (`apps.json`);
  quitting and relaunching the app re-binds its patch automatically.
- **TCC**: the daemon embeds NSAudioCaptureUsageDescription; macOS prompts on
  first capture (System Settings → Privacy & Security → Screen & System Audio
  Recording, if it needs enabling manually).
- Protocol: `getApps` / `apps` / `setAppCapture`.

## [0.4.0 beta] — 2026-06-04

### Added (Phase 2b — Physical devices + drift correction)
- **Physical devices in the grid**: any connected interface can be opted in
  via the new **Devices** popover. Used devices get their own IOProc; their
  inputs become grid sources and outputs become destinations (highlighted in
  the grid with the accent color).
- **ASRC / drift correction** (Section 5.4): per device and direction, an SPSC
  ring buffer with consumer-side resampling — fractional read position whose
  rate follows producerRate/consumerRate trimmed by a fill-level servo
  (±0.2% max), so independent clocks never accumulate into clicks. Linear
  interpolation (honest v1; upgradeable to polyphase without API changes).
- **Hot-plug + re-bind** (Section 7.8): devices are tracked by stable Core
  Audio UID; a used device that disappears keeps its connections in the
  matrix and re-binds automatically when it returns. Listener on
  kAudioHardwarePropertyDevices broadcasts changes live.
- **Engine generalized**: snapshot connections now resolve to
  (buffer, channel) across the backplane ABL and device stagings; the
  backplane IOProc stages resampled device inputs, mixes, and feeds device
  output rings — one clock domain crossing per device, all lock-free.
- Protocol: `getDevices` / `devices` / `setDeviceUse`; used devices persisted
  (`devices.json`).
- **You can now hear the grid**: route any source to a real output device
  (e.g. the Mac's speakers — that's also the monitor path groundwork).

## [0.3.3 beta] — 2026-06-04

### Changed
- **Grid reverted to the stable 0.2.0 layout** by project decision: channel
  count picker (8–64), click to connect + select, removal via Inspector button
  or context menu. The Dante Controller-style grid (frozen headers, hover
  crosshair, toggle-click, banks, LEDs, keyboard, Active filter) returns in
  the UI-polish phase, rebuilt on a solid base.
- Kept from 0.2.1–0.3.2: the **dBFS meter with clip latch**, **scenes in the
  menu bar**, and all daemon-side features (labels, per-channel meters,
  scenes protocol) — they stay functional and wait for their UI.

## [0.3.2 beta] — 2026-06-04

### Added
- **Active filter (default)**: the grid opens showing only channels that
  matter — with connections, labels, or that carried signal this session
  (sticky, so rows don't vanish when audio pauses). "All" exposes the full
  256-pool in banks. A search field narrows either mode by label or number.
  (Section 7.5: "born small and focused".)

### Fixed
- **Row misalignment**: the cell field is now a single Canvas (immediate-mode
  drawing) — headers and cells share the same layout math, so rows and columns
  can never drift, and redraws stay fast even fully expanded.
- Cell interactions on the canvas: click toggles, **⌥-click inspects**
  (replaces the per-cell context menu), hover crosshair unchanged.

## [0.3.1 beta] — 2026-06-04

### Fixed
- **UI freeze with the full grid + meters** (0.3.0 regression). The 10 Hz meter
  broadcast, hover and scroll were each invalidating every grid cell (~2,300
  views). Render path rebuilt: Equatable cells (only changed cells repaint),
  meters/LEDs moved to dedicated observable objects (LEDs publish only on
  threshold transitions), O(1) connection lookup, and scroll offset isolated so
  scrolling repaints only the pinned headers.

## [0.3.0 beta] — 2026-06-04

### Added
- **Editable channel labels** (Section 7.7, anticipated from Phase 7):
  double-click any header to rename ("Mic Host"); persisted by the daemon
  apart from system IDs; shared live across clients.
- **Keyboard navigation**: arrows move a grid cursor, Space toggles the
  connection, ⏎ opens it in the Inspector, Esc clears the cursor.
- **Per-channel signal LEDs** in headers (green = signal above -50 dBFS),
  fed by new per-channel input/output peaks computed in the engine — find
  where audio lives before patching, even with zero connections.
- **1:1 identity patch** between banks of 8 (with a guard against patching a
  bank onto itself, which feeds back on a loopback device).
- **Scenes** (anticipated from Phase 7): save the current matrix under a name,
  apply atomically (single snapshot swap — no audible intermediate states),
  delete; persisted by the daemon. Quick-switch via the new **menu bar panel**
  (status + scenes + save field), per Section 7.3.
- Protocol: `labels`/`setLabel`, `scenes`/`saveScene`/`applyScene`/`deleteScene`,
  and `levels` extended with per-channel source/destination peaks.

## [0.2.1 beta] — 2026-06-04

### Changed (grid UX, Dante Controller-style)
- **Frozen headers**: row labels and column numbers stay pinned while the cell
  area scrolls (synced via scroll geometry).
- **Hover crosshair**: the row/column under the pointer highlight, with a live
  "In X → Out Y" readout in the grid header.
- **Click = subscribe / click again = unsubscribe.** Remove button dropped;
  right-click → Inspect opens gain/meter (creating a connection also opens it).
- **Collapsible banks of 8** per axis (default: first 16 channels visible),
  with expand/collapse-all menu — scales to 256 channels and beyond.
- **Device identity**: the device being patched is named in the grid header and
  in the Inspector (groundwork for apps with icons in Phase 3).
- **Real dBFS meter**: -60…+6 scale with 0 dBFS tick, green/yellow/red zones,
  numeric readout and a click-to-reset **CLIP latch** — you can now tell
  exactly when the post-gain peak crosses 0 dBFS.
- Gain gets a "0 dB" reset shortcut.

## [0.2.0 beta] — 2026-06-04

### Added (Phase 2 — Grid engine)
- **Audio engine**: IOProc attached to the backplane; the patch matrix is applied
  to real audio with **per-connection gain** (vDSP mixing, lock-free snapshot
  handoff to the audio thread, post-gain peak meters).
- **Matrix persistence**: connections survive daemon restarts
  (`~/Library/Application Support/Hydra/matrix.json`).
- **Protocol**: `getMatrix` / `matrix` / `setConnection` / `removeConnection` /
  `levels` messages; status now reports engine state.
- **Grid UI**: cross-point matrix (8–64 visible channels), click to connect,
  selection opens the **Inspector** (gain slider in dB, live meter, remove).
- **Design**: macOS Tahoe **Liquid Glass** (glass chips, glass buttons);
  deployment target bumped to macOS 26.
- **About window**: GPL notice and third-party credits (BlackHole, VST3) moved
  to About / Acknowledgements — removed from the main window footer.

### Honest state
- Phase 2 routes backplane channel → backplane channel only. Physical devices
  (with ASRC) are Phase 2b; per-app capture is Phase 3; monitor/listen needs a
  physical output path, so it ships with 2b — no placeholder button until then.

## [0.1.0 beta] — Phase 1 verified on the test VM 2026-06-04

## [0.1.0 beta] — 2026-06-04

### Added (Phase 1 — Foundation)
- Project skeleton (Swift Package Manager) with three targets:
  - `HydraCore` — shared constants, data model and WebSocket message types (single source of truth).
  - `hydrad` — minimal daemon: detects the backplane via Core Audio and serves a local WebSocket (`127.0.0.1:59731`).
  - `HydraApp` — minimal SwiftUI app: connects to the daemon and shows daemon/backplane status (dark theme, indigo accent, English UI).
- `Backplane/build_and_install.sh` — builds the 256×256 backplane ("Hydra Virtual Soundcard") from BlackHole source (SIP stays on).
- Host/VM workflow: `Scripts/host_build.sh` (one command on the host: tests + driver + universal binaries → `dist/`) and `Scripts/vm_install.sh` (one command on the UTM VM, via SMB-shared folder: install driver + binaries, restart coreaudiod, verify).
- `LICENSE` (GPL-3.0), `THIRD_PARTY_NOTICES.md` (BlackHole credited), this `CHANGELOG.md`.

### Honest state
- No audio routing yet — the patch matrix engine is Phase 2.
- The app shows real status only (no decorative screens).
