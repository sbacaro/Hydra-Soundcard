# Graph Report - .  (2026-07-21)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 4067 nodes · 9514 edges · 355 communities (258 shown, 97 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 494 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `76a0f92e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ring_buffer.rs
- Hydra.c
- WSMessage
- FlowsTransmitter
- ProcessTapManager
- Hydra
- DaemonClient
- Kind
- String
- SharedPluginHost
- Sendable
- channels_subscriber.rs
- Foundation
- MatrixStore
- View
- StripManager
- Service
- OSCMessage
- ClockOverlay
- DeviceServer
- RouteManager
- CodingKeys
- InstallerState
- CoreMIDIBackend
- View
- log
- String
- flows_rx.rs
- HiQnet
- MultiIpIoError
- Int
- ModuleManager
- BroadcasterHandle
- SurfaceBridge
- Value
- GridView
- RealTimeSamplesReceiver
- TransmitMulticasts
- GridEntry
- MediaClock
- MenuBarPanel
- proto_arc.rs
- Result
- Updater
- NdiManager
- ResponderMemoryEntry
- Aes67ParserExtraTests
- BridgeManager
- ChannelRing
- PtpClock
- .emit
- SettingsView.swift
- FlowChainCard
- PluginHost
- Aes67Tx
- AppKit
- .new
- run_server
- PolyphaseResampler
- PtpParsingTests
- SidebarView
- DeviceManager
- MdnsClient
- MetricsReporter
- DeviceInfo
- DeviceOutputTap
- InstallerWindowDelegate
- ResampleServoTests
- DeviceMDNSResponder
- DiscoveryBuilder
- Aes67Manager
- run_server
- Aes67Stream
- bytes.rs
- SidebarTab
- Cow
- Aes67Rx
- NodeKind
- String
- DanteClockBrowser
- AppDelegate
- Message
- HiQnetServer
- .impl_run
- UdpSocketWrapper
- .backplaneDeviceID
- SurfaceManager
- Settings
- paginate_make_response
- Connection
- CodingKeys
- hydra_ndi.c
- InterfaceStore
- Headers/hydra_plugin_shm.h
- ChannelsSubscriberInternal<P, B>
- .new_realtime
- BroadcasterBuilder
- EnginePresence
- Coordinator
- .menuBarWave
- DispatchQueue
- DataType
- Connection
- AudioEngine
- include/hydra_plugin_shm.h
- samples_utils.rs
- make_channel_change_notification
- Aes67Tests
- RealTimeBoxReceiver
- Context
- CommandPalette
- Kind
- Component
- common.rs
- run_server
- DanteClockBrowser
- DanteClockBrowser
- build_and_install.sh
- release.sh
- hydra-plugin-host.build/DerivedSources/GeneratedAssetSymbols.swift
- install_local.sh
- PatchScene
- ConfigStore
- GFAD
- SubObject
- WindowAccessor
- generate_xcodeproj.rb
- Diagnostics
- FlowEndpoint
- OscServer
- TLSW
- proto_cmc.rs
- SwiftUI
- AppInfo
- bridges_install.sh
- StripInfo
- build_installer.sh
- render
- NetworkUtils.swift
- CHLCD
- build_pkg.sh
- DanteController/postinstall
- common.sh
- ConnectionState
- SlotsCtl
- Option
- set_current_thread_realtime
- HydraApp
- PackageDescription
- installer_common.sh
- DanteController/preinstall
- bridges_uninstall.sh
- fetch_vst3sdk.sh
- install_and_test.sh
- .runScanWorkerIfRequested
- scripts/postinstall
- Dante Activator.app/Contents/Frameworks/nwjs Framework.framework/Versions/145.0.7632.76/Resources/install.sh
- Chromium Framework.framework/Versions/145.0.7632.76/Resources/install.sh
- Dante Updater.app/Contents/Frameworks/nwjs Framework.framework/Versions/145.0.7632.76/Resources/install.sh
- launch_conmon.sh
- dante_use.sh
- delete.sh
- relaunchDaemon.sh
- use.sh
- DanteUpdateHelper/uninstall.sh
- conmon_pre
- DanteControllerPackage/postinstall
- DanteUpdateHelper/postinstall
- Resources/uninstall.sh
- DanteVirtualSoundcard/postinstall
- DanteVirtualSoundcard/preinstall
- DVS_User_Interface/postinstall
- ExternalRBOutput<T>
- Script-5523C934D0F4E104405D721B.sh
- Script-C641665DE93AF2886FB53446.sh
- 07f9d1f5e9a027039b0279711d311fe2.xcbuilddata/attachments/565ed22afe643a0d594ab695cd305a5d
- bd00099a8027616d4420e90fe828d093.xcbuilddata/attachments/565ed22afe643a0d594ab695cd305a5d
- c6fd4cd02d190c7c45167ca9191d1fce.xcbuilddata/attachments/565ed22afe643a0d594ab695cd305a5d
- d4a934bedee6d794ecc9abaedd688e3e.xcbuilddata/attachments/565ed22afe643a0d594ab695cd305a5d
- FlowInfo
- Set
- Binding
- Content
- FlowInfo
- Void
- Bool
- CGFloat
- CGRect
- CGSize
- Content
- Context
- Int
- Set
- Void
- CGFloat
- CGSize
- Color
- Content
- Double
- Void
- Binding
- Bool
- Context
- Notification
- Date
- PatchScene
- URL
- Content
- LocalizedStringKey
- Set
- Double
- Float
- Int32
- UInt16
- URL
- UUID
- Double
- Int32
- Process
- URL
- Void
- FlowInfo
- Bool
- Color
- Context
- String
- Self
- Vec
- BTreeMap
- Ipv4Addr
- Option
- PathBuf
- Self
- Option
- Receiver
- SocketAddr
- UdpSocket
- BTreeSet
- Error
- NonZeroU32
- Vec

## God Nodes (most connected - your core abstractions)
1. `WSMessage` - 135 edges
2. `DaemonClient` - 83 edges
3. `Foundation` - 77 edges
4. `log()` - 71 edges
5. `Kind` - 70 edges
6. `MatrixStore` - 68 edges
7. `HydraCore` - 60 edges
8. `CodingKeys` - 57 edges
9. `StripManager` - 48 edges
10. `View` - 47 edges

## Surprising Connections (you probably didn't know these)
- `LanguagePicker` --references--> `View`  [EXTRACTED]
  Sources/HydraApp/AppLanguage.swift → Sources/HydraApp/MenuBarPanel.swift
- `ContentView` --calls--> `InstallManager`  [INFERRED]
  Sources/HydraApp/ContentView.swift → Sources/HydraApp/InstallManager.swift
- `MatrixStore` --calls--> `PatchMatrix`  [INFERRED]
  Sources/hydrad/MatrixStore.swift → Sources/HydraCore/PatchMatrix.swift
- `SurfaceManager` --calls--> `SurfaceBridge`  [INFERRED]
  Sources/hydrad/SurfaceManager.swift → Sources/HydraSurface/SurfaceBridge.swift
- `run_server()` --calls--> `make_channel_change_notification()`  [INFERRED]
  Sources/Inferno/inferno_aoip/src/device_server/arc_server.rs → Sources/Inferno/inferno_aoip/src/protocol/mcast.rs

## Import Cycles
- 2-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/mdns_server.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/channels_subscriber.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_rx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/channels_subscriber.rs`
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/tx_multicasts.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 4-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/tx_multicasts.rs -> Sources/Inferno/inferno_aoip/src/device_server/mdns_server.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`

## Communities (355 total, 97 thin omitted)

### Community 0 - "ring_buffer.rs"
Cohesion: 0.06
Nodes (71): Clone, ExactSizeIterator, ExternalBuffer, ExternalBuffer<Atomic<Sample>>, ExternalBuffer<T>, ExternalBufferParameters, ExternalBufferParameters<T>, ExternalRBInput (+63 more)

### Community 1 - "Hydra.c"
Cohesion: 0.09
Nodes (85): AudioObjectPropertyAddress, AudioServerPlugInClientInfo, AudioServerPlugInDriverRef, AudioServerPlugInHostRef, AudioServerPlugInIOCycleInfo, BlackHole_AbortDeviceConfigurationChange(), BlackHole_AddDeviceClient(), BlackHole_AddRef() (+77 more)

### Community 2 - "WSMessage"
Cohesion: 0.03
Nodes (78): Aes67Payload, Encoder, LevelsPayload, MatrixPayload, ScenesPayload, Connection, PatchScene, WSMessage (+70 more)

### Community 3 - "FlowsTransmitter"
Cohesion: 0.05
Nodes (56): AtomicSample, LongClockDiff, SmallRng, Command, Flow, FlowData, FlowInfo, FlowsTransmitter (+48 more)

### Community 4 - "ProcessTapManager"
Cohesion: 0.06
Nodes (33): AudioObjectPropertySelector, NSRunningApplication, ResponsibleFn, ConnectionIndex, Gain, PatchMatrix, Bool, Connection (+25 more)

### Community 5 - "Hydra"
Cohesion: 0.06
Nodes (16): Float, BridgeSpec, Hydra, SurfacePreset, Bool, Int, String, PatchValidation (+8 more)

### Community 6 - "DaemonClient"
Cohesion: 0.08
Nodes (17): GridEntry, ConnMeters, DaemonClient, SignalFlags, Bool, Connection, Float, HydraEvent (+9 more)

### Community 7 - "Kind"
Cohesion: 0.03
Nodes (68): Kind, aes67, applyScene, apps, bridges, config, connectSurfaceConsole, createInterface (+60 more)

### Community 8 - "String"
Cohesion: 0.09
Nodes (19): Decoder, Double, ChannelLabelsPayload, ChannelScope, input, output, ConfigPayload, CreateInterfacePayload (+11 more)

### Community 9 - "SharedPluginHost"
Cohesion: 0.07
Nodes (32): Pipe, InstallManager, InstallResult, failure, success, Phase, failed, idle (+24 more)

### Community 10 - "Sendable"
Cohesion: 0.12
Nodes (45): Codable, Equatable, Identifiable, Sendable, BridgeInfo, BridgeRole, both, input (+37 more)

### Community 11 - "channels_subscriber.rs"
Cohesion: 0.09
Nodes (43): ChannelOtherEnd, ChannelsBuffering, ChannelsSubscriber, ChannelsSubscriberInternal, ChannelSubscription, Command, ExternalBuffering, Flow (+35 more)

### Community 12 - "Foundation"
Cohesion: 0.09
Nodes (14): Accelerate, AVFoundation, CoreAudio, Foundation, HydraCore, HydraModuleABI, HydraNDIShim, HydraRT (+6 more)

### Community 13 - "MatrixStore"
Cohesion: 0.10
Nodes (24): AnyObject, AudioBufferList, ContiguousArray, os_unfair_lock, Snapshot, Conn, EngineTap, InMeter (+16 more)

### Community 14 - "View"
Cohesion: 0.06
Nodes (26): NavigationSplitViewVisibility, AboutView, LocalizedStringKey, ContentView, Binding, Bool, Color, View (+18 more)

### Community 15 - "StripManager"
Cohesion: 0.09
Nodes (27): ChainTap, EditorRef, EditorTarget, local, none, remote, PluginPrefs, ScanCache (+19 more)

### Community 16 - "Service"
Cohesion: 0.06
Nodes (28): DnsMessage, IntoName, IpAddr, Ord, Ordering, PartialOrd, ServiceBuilderError, Borrow (+20 more)

### Community 17 - "OSCMessage"
Cohesion: 0.10
Nodes (18): OSCArg, float, int, string, OSCMessage, OSCParser, Data, Float (+10 more)

### Community 18 - "ClockOverlay"
Cohesion: 0.08
Nodes (31): c_int, ClockId, JoinError, OverlayReceiveError, AsyncClient, blocking_send_recv(), BlockingClient, client_socket_path() (+23 more)

### Community 19 - "DeviceServer"
Cohesion: 0.09
Nodes (34): Fn, DeviceServer, Arc, Atomic, AtomicUsize, B, Box, BTreeMap (+26 more)

### Community 20 - "RouteManager"
Cohesion: 0.09
Nodes (21): BridgeManager, ConfigPayload, DeviceManager, DeviceOutputTap, Int32, MatrixStore, Process, conmon_post script (+13 more)

### Community 21 - "CodingKeys"
Cohesion: 0.04
Nodes (48): CodingKeys, aes67TX, appTapMakeupDB, backplaneDeviceName, backplaneInstalled, base, category, channelIndex (+40 more)

### Community 22 - "InstallerState"
Cohesion: 0.07
Nodes (23): ComponentCatalog, FooterView, Bool, ComponentStatus, failed, installed, installing, pending (+15 more)

### Community 23 - "CoreMIDIBackend"
Cohesion: 0.08
Nodes (29): Addr, BTreeSet, CoreMIDI, CustomStringConvertible, Error, Ipv6Addr, MIDIEndpointRef, MIDIPacketList (+21 more)

### Community 24 - "View"
Cohesion: 0.09
Nodes (36): Aes67Stream, AppInfo, BridgeRole, ChannelFocus, ChannelScope, ConnMeters, Content, DaemonClient (+28 more)

### Community 25 - "log"
Cohesion: 0.10
Nodes (14): DaemonContext, NWParameters, ObjectIdentifier, DaemonContext, DaemonRuntime, DispatchSourceTimer, NWConnection, log() (+6 more)

### Community 26 - "String"
Cohesion: 0.08
Nodes (18): PluginCategory, all, dynamics, eqFilter, favorites, instruments, masteringTools, modulation (+10 more)

### Community 27 - "flows_rx.rs"
Cohesion: 0.13
Nodes (29): AtomicI32, Poll, Channel, Command, FlowInfo, FlowsReceiver, FlowsReceiver<P>, FlowsReceiverInternal (+21 more)

### Community 28 - "HiQnet"
Cohesion: 0.17
Nodes (12): Address, Array, Flags, Frame, HiQnet, Subscription, Int, UInt32 (+4 more)

### Community 29 - "MultiIpIoError"
Cohesion: 0.11
Nodes (26): DnsRecordType, Discovery, discovery_packet(), DiscoveryBuilderError, DiscoveryHandle, DiscoveryHandleDrop, DiscoveryHandleInner, Drop (+18 more)

### Community 30 - "Int"
Cohesion: 0.10
Nodes (20): Int, Decoder, Event, fader, ping, scribble, switchState, HUI (+12 more)

### Community 31 - "ModuleManager"
Cohesion: 0.12
Nodes (19): CChar, HydraModule, moduleHostDeliver(), moduleHostLog(), moduleHostSourcesChanged(), ModuleManager, ModuleRx, ModuleTx (+11 more)

### Community 32 - "BroadcasterHandle"
Cohesion: 0.08
Nodes (24): Display, Formatter, BroadcasterBuilderError, Error, ServiceDnsPacketBuilderError, BroadcasterHandle, BroadcasterHandleDrop, BroadcasterHandleInner (+16 more)

### Community 33 - "SurfaceBridge"
Cohesion: 0.14
Nodes (13): Never, Observation, MIDIBackend, Config, SlotKey, SurfaceBridge, Bool, Int (+5 more)

### Community 34 - "Value"
Cohesion: 0.08
Nodes (24): Int8, Binding, Bool, DispatchWorkItem, TimeInterval, Void, SyncedValue, Double (+16 more)

### Community 35 - "GridView"
Cohesion: 0.10
Nodes (27): Axis, Bool, CGFloat, CGRect, CGSize, GeometryEffect, GraphicsContext, GroupDef (+19 more)

### Community 36 - "RealTimeSamplesReceiver"
Cohesion: 0.13
Nodes (23): Clock, ClockDiff, wrapped_diff(), Channel, Channel<P>, Command, get_min_max_end_timestamps(), PeriodicSamplesCollector (+15 more)

### Community 37 - "TransmitMulticasts"
Cohesion: 0.12
Nodes (23): Bundle, Arc, AtomicBool, AtomicU32, BTreeMap, Error, Ipv4Addr, Mutex (+15 more)

### Community 38 - "GridEntry"
Cohesion: 0.19
Nodes (12): Hashable, PatchPoint, DeviceViewPatch, SignalDotPublic, Binding, Bool, CGFloat, Color (+4 more)

### Community 39 - "MediaClock"
Cohesion: 0.12
Nodes (20): FineClock, async_clock_receiver_to_realtime(), make_shared_media_clock(), media_clock_new_not_ready(), media_clock_update_overlay_becomes_ready(), media_clock_update_overlay_replaces(), MediaClock, Arc (+12 more)

### Community 40 - "MenuBarPanel"
Cohesion: 0.08
Nodes (15): MenuBarPanel, Color, Date, destination, ChannelPairing, formatElapsed(), LoadSeverity, critical (+7 more)

### Community 41 - "proto_arc.rs"
Cohesion: 0.07
Nodes (19): ChannelDescriptor, common_channels_descriptor_new_matches_device_info(), CommonChannelsDescriptor, Descriptor2, deserialize_items(), deserialize_items_empty(), DestinationSocketDescriptor, Flags2 (+11 more)

### Community 42 - "Result"
Cohesion: 0.14
Nodes (18): Copy, Iface, Socket, InterfacedMdnsSocket, InterfacedMdnsSocket<AsyncUdpSocket, Iface>, InterfacedMdnsSocket<Socket, Iface>, InterfacedMdnsSocket<UdpSocket, Iface>, MdnsSocket (+10 more)

### Community 43 - "Updater"
Cohesion: 0.13
Nodes (17): Decodable, GHAsset, GHRelease, Release, Bool, Data, Error, TimeInterval (+9 more)

### Community 44 - "NdiManager"
Cohesion: 0.15
Nodes (13): NdiManager, NdiRx, NdiTx, Bool, DispatchSourceTimer, Double, Float, Int (+5 more)

### Community 45 - "ResponderMemoryEntry"
Cohesion: 0.10
Nodes (20): Cell, Hash, HashSet, DiscoveryEvent, Arc, Responder, ResponderMemory, ResponderMemoryEntry (+12 more)

### Community 46 - "Aes67ParserExtraTests"
Cohesion: 0.15
Nodes (6): SDPParser, Data, Aes67ParserExtraTests, Data, Int, UInt8

### Community 47 - "BridgeManager"
Cohesion: 0.16
Nodes (11): BridgeManager, Persisted, PresentBridge, AudioObjectID, Bool, DispatchWorkItem, Double, Int (+3 more)

### Community 48 - "ChannelRing"
Cohesion: 0.18
Nodes (13): ABLUtil, ChannelRing, Bool, Double, Float, Int, Int64, UnsafeMutablePointer (+5 more)

### Community 49 - "PtpClock"
Cohesion: 0.22
Nodes (12): Master, PtpClock, PtpStatus, Snapshot, Data, DispatchSourceTimer, Double, Int (+4 more)

### Community 50 - ".emit"
Cohesion: 0.14
Nodes (14): AVAudioFile, AVAudioPCMBuffer, EventCenter, HydraEvent, String, Void, Recording, RecordingManager (+6 more)

### Community 51 - "SettingsView.swift"
Cohesion: 0.10
Nodes (20): ChannelLabelsPayload, Date, PatchScene, AdvancedSettingsPane, AudioSettingsPane, ControlSettingsPane, GeneralSettingsPane, PluginRow (+12 more)

### Community 52 - "FlowChainCard"
Cohesion: 0.15
Nodes (9): FlowInfo, PhysicalDeviceInfo, FlowChainCard, FluxView, Bool, Color, Int, String (+1 more)

### Community 53 - "PluginHost"
Cohesion: 0.15
Nodes (16): HydraPluginHostABI, HydraVST, ChainCommand, ChainManager, hlog(), PluginHost, PluginSpec, Data (+8 more)

### Community 54 - "Aes67Tx"
Cohesion: 0.13
Nodes (15): Aes67Tx, Aes67TxManager, localIPv4Address(), Bool, DispatchSourceTimer, Double, Float, Int (+7 more)

### Community 55 - "AppKit"
Cohesion: 0.10
Nodes (17): AppKit, Carbon, Combine, Commands, CryptoKit, Darwin, HydraDaemon, os (+9 more)

### Community 56 - ".new"
Cohesion: 0.23
Nodes (17): AtomicU16, FlowControlError, FlowsControlClient, minimal_device_info(), Arc, Box, ByteBuffer, Error (+9 more)

### Community 57 - "run_server"
Cohesion: 0.15
Nodes (19): Serialize, Arc, BroadcastReceiver, Mutex, Option, Receiver, Sender, run_server() (+11 more)

### Community 58 - "PolyphaseResampler"
Cohesion: 0.19
Nodes (6): PolyphaseResampler, ArraySlice, Double, Float, Int, PolyphaseResamplerTests

### Community 59 - "PtpParsingTests"
Cohesion: 0.13
Nodes (7): PtpParsing, ArraySlice, Bool, Double, Int, UInt8, PtpParsingTests

### Community 60 - "SidebarView"
Cohesion: 0.15
Nodes (9): BridgeInfo, ModuleSourceInfo, NdiSourceInfo, ManageBridgesSheet, SidebarView, Bool, Int, SurfacePayload (+1 more)

### Community 61 - "DeviceManager"
Cohesion: 0.16
Nodes (13): DeviceIO, DeviceManager, Present, AudioDeviceIOProcID, AudioObjectID, Bool, Double, Float (+5 more)

### Community 62 - "MdnsClient"
Cohesion: 0.24
Nodes (14): RecordType, MdnsClient, Arc, Box, BTreeMap, DnsResponse, Duration, Error (+6 more)

### Community 63 - "MetricsReporter"
Cohesion: 0.13
Nodes (16): Logger, MXDiagnosticPayload, MXMetricManagerSubscriber, MXMetricPayload, MetricsReporter, Data, URL, Category (+8 more)

### Community 64 - "DeviceInfo"
Cohesion: 0.15
Nodes (18): MacAddr, Channel, DeviceInfo, dummy_device_info(), five_ms_at_48000_hz(), large_values_no_overflow(), one_second_at_44100_hz(), one_second_at_48000_hz() (+10 more)

### Community 65 - "DeviceOutputTap"
Cohesion: 0.17
Nodes (11): CATapDescription, DeviceOutputTap, AudioDeviceIOProcID, AudioObjectID, Bool, Double, Float, Int (+3 more)

### Community 66 - "InstallerWindowDelegate"
Cohesion: 0.14
Nodes (13): NSApplicationDelegate, NSObject, NSWindowDelegate, AppDelegate, HydraInstallerApp, InstallerWindowDelegate, Reason, close (+5 more)

### Community 67 - "ResampleServoTests"
Cohesion: 0.15
Nodes (5): ResampleServo, Bool, Double, Int, ResampleServoTests

### Community 68 - "DeviceMDNSResponder"
Cohesion: 0.18
Nodes (13): DeviceMDNSResponder, in_addr_type(), kv(), multicast_ip_to_name(), Arc, BTreeMap, Ipv4Addr, Name (+5 more)

### Community 69 - "DiscoveryBuilder"
Cohesion: 0.16
Nodes (9): DiscoveryBuilder, Default, DnsName, Duration, Option, Result, Self, TargetInterfaceV4 (+1 more)

### Community 70 - "Aes67Manager"
Cohesion: 0.18
Nodes (8): NWBrowser, Aes67Manager, Bool, Data, Date, DispatchSourceTimer, Set, URL

### Community 71 - "run_server"
Cohesion: 0.23
Nodes (10): PeaksCallback, Multicaster, Multicaster<'s>, Arc, BroadcastReceiver, Option, Receiver, RwLock (+2 more)

### Community 72 - "Aes67Stream"
Cohesion: 0.25
Nodes (12): Aes67Device, Aes67Payload, Aes67Stream, Aes67TxInfo, Announcement, SAPParser, SubscribeStreamPayload, Bool (+4 more)

### Community 73 - "bytes.rs"
Cohesion: 0.16
Nodes (13): align_wpos(), ByteBuffer, Option, test_align_wpos_various_alignments(), test_write_0term_str_or_0_to_bytebuffer_some_and_none(), test_write_0term_str_to_bytebuffer_offset_and_trailing_zero(), test_write_str_to_buffer_empty_string(), test_write_str_to_buffer_exact_fit() (+5 more)

### Community 74 - "SidebarTab"
Cohesion: 0.11
Nodes (16): CaseIterable, Color, InstallerState, InstallerStep, PluginPickerSheet, StripInfo, ViewMode, category (+8 more)

### Community 75 - "Cow"
Cohesion: 0.18
Nodes (7): Cow, Sized, IntoServiceTxt, &'static str, &'static [u8], &'static [u8; N], Vec<u8>

### Community 76 - "Aes67Rx"
Cohesion: 0.17
Nodes (11): Int16, Aes67Rx, MulticastReceiver, DispatchSourceRead, Double, Float, Int, Int32 (+3 more)

### Community 77 - "NodeKind"
Cohesion: 0.18
Nodes (13): OptionSet, Channel, Node, NodeDirections, NodeKind, aes67, app, backplane (+5 more)

### Community 78 - "String"
Cohesion: 0.19
Nodes (11): ChannelSettings, Arc, Channel, Self, Vec, SavedChannels, SavedChannelsSettings, TestConfig (+3 more)

### Community 79 - "DanteClockBrowser"
Cohesion: 0.16
Nodes (10): NetService, NetServiceBrowser, NetServiceBrowserDelegate, NetServiceDelegate, NSNumber, DanteClockBrowser, Bool, Data (+2 more)

### Community 80 - "AppDelegate"
Cohesion: 0.21
Nodes (6): DaemonService, AppDelegate, Bool, Notification, NSApplication, NSWindow

### Community 81 - "Message"
Cohesion: 0.11
Nodes (18): Message, discoInfo, getAttributes, getNetworkInfo, getVDList, goodbye, hello, multiObjectParamSet (+10 more)

### Community 82 - "HiQnetServer"
Cohesion: 0.22
Nodes (8): HiQnetServer, MeterListener, Bool, NWConnection, NWListener, UInt16, UInt8, Void

### Community 83 - ".impl_run"
Cohesion: 0.21
Nodes (12): AsyncUdpSocket, Broadcaster, BroadcasterConfig, Arc, BTreeSet, Option, Receiver, Result (+4 more)

### Community 84 - "UdpSocketWrapper"
Cohesion: 0.22
Nodes (10): Receiver, SocketAddr, create_mio_udp_socket(), create_tokio_udp_socket(), ReceiveBuffer, Ipv4Addr, Result, Self (+2 more)

### Community 85 - ".backplaneDeviceID"
Cohesion: 0.29
Nodes (6): BackplaneProbe, AudioObjectID, AudioObjectPropertyScope, Bool, Double, Int

### Community 86 - "SurfaceManager"
Cohesion: 0.24
Nodes (3): SurfaceManager, DispatchSourceTimer, Void

### Community 87 - "Settings"
Cohesion: 0.19
Nodes (11): BTreeMap, DeviceInfo, Ipv4Addr, Option, PathBuf, Self, Args, String (+3 more)

### Community 88 - "paginate_make_response"
Cohesion: 0.28
Nodes (15): InItem, Iterator, OutItem, extract_start_index(), ItemsInPacketIterator<'a, T>, paginate_make_response(), paginate_respond(), ByteBuffer (+7 more)

### Community 89 - "Connection"
Cohesion: 0.17
Nodes (4): Connection, PatchPoint, Float, ModelsTests

### Community 90 - "CodingKeys"
Cohesion: 0.13
Nodes (15): CodingKey, CodingKeys, address, aes67On, channels, devices, flowIndex, interfaceID (+7 more)

### Community 91 - "hydra_ndi.c"
Cohesion: 0.14
Nodes (4): hndi_source_t, hndi_find_sources(), hndi_load(), try_dlopen()

### Community 92 - "InterfaceStore"
Cohesion: 0.27
Nodes (5): InterfaceStore, Bool, Int, Range, UUID

### Community 93 - "Headers/hydra_plugin_shm.h"
Cohesion: 0.18
Nodes (7): hydra_plugin_cmd, hydra_plugin_shm, hydra_plugin_shm_bytes(), hydra_plugin_shm_cmd(), hydra_plugin_shm_input(), hydra_plugin_shm_output(), hydra_plugin_shm_slot_floats()

### Community 94 - "ChannelsSubscriberInternal<P, B>"
Cohesion: 0.27
Nodes (4): ChannelsSubscriberInternal<P, B>, Flow<P>, IntoIterator, Item

### Community 95 - ".new_realtime"
Cohesion: 0.21
Nodes (9): Arc, Box, Future, Output, Pin, SamplesCallback, Self, Send (+1 more)

### Community 96 - "BroadcasterBuilder"
Cohesion: 0.22
Nodes (7): BroadcasterBuilder, BTreeSet, Default, Result, Self, TargetInterfaceV4, TargetInterfaceV6

### Community 97 - "EnginePresence"
Cohesion: 0.19
Nodes (7): EnginePresence, noBackplane, offline, running, stopped, Bool, EnginePresenceTests

### Community 98 - "Coordinator"
Cohesion: 0.22
Nodes (7): Binding, Notification, NSSearchField, NSSearchFieldDelegate, Coordinator, SearchField, String

### Community 99 - ".menuBarWave"
Cohesion: 0.23
Nodes (10): CGPoint, NSImage, Path, Shape, MenuBarStatusLabel, BrandMark, IconPack, CGFloat (+2 more)

### Community 100 - "DispatchQueue"
Cohesion: 0.27
Nodes (6): DispatchQueue, HiQnetDiscovery, DispatchSourceRead, Int32, UInt8, Void

### Community 101 - "DataType"
Cohesion: 0.15
Nodes (13): DataType, block, byte, float32, float64, long, long64, string (+5 more)

### Community 102 - "Connection"
Cohesion: 0.28
Nodes (5): Connection, make_packet(), RemoteInfo, Option, SocketAddr

### Community 103 - "AudioEngine"
Cohesion: 0.24
Nodes (9): AudioObjectPropertyListenerBlock, HydraSignpost, AudioEngine, EngineMetrics, AudioDeviceIOProcID, AudioObjectID, Bool, Double (+1 more)

### Community 104 - "include/hydra_plugin_shm.h"
Cohesion: 0.24
Nodes (7): hydra_plugin_cmd, hydra_plugin_shm, hydra_plugin_shm_bytes(), hydra_plugin_shm_cmd(), hydra_plugin_shm_input(), hydra_plugin_shm_output(), hydra_plugin_shm_slot_floats()

### Community 106 - "make_channel_change_notification"
Cohesion: 0.23
Nodes (10): make_channel_change_notification(), make_channel_change_notification_empty_iterator(), make_channel_change_notification_returns_start_code_and_opcode(), make_packet(), make_packet_produces_correct_header_bytes(), make_packet_total_length_equals_header_length_plus_content_len(), IntoIterator, Item (+2 more)

### Community 107 - "Aes67Tests"
Cohesion: 0.23
Nodes (4): Aes67Tests, Bool, Data, UInt8

### Community 108 - "RealTimeBoxReceiver"
Cohesion: 0.33
Nodes (8): AtomicOptionBox, channel(), RealTimeBoxReceiver, RealTimeBoxSender, RealTimeBoxSender<T>, Arc, Box, Shared

### Community 109 - "Context"
Cohesion: 0.31
Nodes (6): Context, NSClickGestureRecognizer, NSGestureRecognizerRepresentable, NSVisualEffectView, RightClickGesture, VisualEffectView

### Community 110 - "CommandPalette"
Cohesion: 0.24
Nodes (7): Element, Array, CommandPalette, PaletteAction, Bool, Int, Void

### Community 111 - "Kind"
Cohesion: 0.20
Nodes (9): Kind, error, info, installed, resourceLost, resourceRestored, warning, Date (+1 more)

### Community 112 - "Component"
Cohesion: 0.21
Nodes (11): Component, Bool, Double, AppleScriptResult, InstallerEngine, Bool, Double, Void (+3 more)

### Community 113 - "common.rs"
Cohesion: 0.22
Nodes (4): log_and_forget_err(), log_and_forget_ok(), LogAndForget, Result<T, E>

### Community 114 - "run_server"
Cohesion: 0.22
Nodes (10): Arc, BroadcastReceiver, Mutex, Option, run_server(), make_u16(), read_0term_str_from_buffer(), Box (+2 more)

### Community 115 - "DanteClockBrowser"
Cohesion: 0.18
Nodes (10): DanteClockBrowser, -initOBJC_DESIGNATED_INITIALIZER, -netServiceBrowserdidFindServicemoreComing, -netServiceBrowserdidRemoveServicemoreComing, -netServicedidNotResolve, -netServiceDidResolveAddress, -netServicedidUpdateTXTRecordData, NSNetServiceBrowserDelegate (+2 more)

### Community 116 - "DanteClockBrowser"
Cohesion: 0.18
Nodes (10): DanteClockBrowser, -initOBJC_DESIGNATED_INITIALIZER, -netServiceBrowserdidFindServicemoreComing, -netServiceBrowserdidRemoveServicemoreComing, -netServicedidNotResolve, -netServiceDidResolveAddress, -netServicedidUpdateTXTRecordData, NSNetServiceBrowserDelegate (+2 more)

### Community 117 - "build_and_install.sh"
Cohesion: 0.60
Nodes (9): build_driver(), customize_source(), fail(), fetch_source(), install_driver(), log(), require_xcode(), build_and_install.sh script (+1 more)

### Community 118 - "release.sh"
Cohesion: 0.29
Nodes (5): fail(), header(), note(), run(), release.sh script

### Community 120 - "hydra-plugin-host.build/DerivedSources/GeneratedAssetSymbols.swift"
Cohesion: 0.22
Nodes (7): DeveloperToolsSupport, DeveloperToolsSupport.ColorResource, DeveloperToolsSupport.ImageResource, ResourceBundleClass, DeveloperToolsSupport.ColorResource, DeveloperToolsSupport.ImageResource, ResourceBundleClass

### Community 121 - "install_local.sh"
Cohesion: 0.58
Nodes (8): device_visible(), do_install(), do_status(), do_uninstall(), fail(), log(), restart_coreaudiod(), install_local.sh script

### Community 122 - "PatchScene"
Cohesion: 0.31
Nodes (3): PatchScene, SceneStore, Connection

### Community 123 - "ConfigStore"
Cohesion: 0.28
Nodes (4): ConfigStore, hydraSupportURL(), LabelStore, URL

### Community 124 - "GFAD"
Cohesion: 0.22
Nodes (9): GFAD, enable, faderMode, faderUByteValue, faderValue, glowColour, glowFunction, motorUByteValue (+1 more)

### Community 125 - "SubObject"
Cohesion: 0.22
Nodes (8): SubObject, fader, lcd, onSw, selSw, soloSw, Bool, Int

### Community 126 - "WindowAccessor"
Cohesion: 0.32
Nodes (6): NSView, NSViewRepresentable, Context, NSWindow, Void, WindowAccessor

### Community 127 - "generate_xcodeproj.rb"
Cohesion: 0.36
Nodes (4): c_framework(), common!(), each_config(), sync_dir()

### Community 130 - "FlowEndpoint"
Cohesion: 0.29
Nodes (7): FlowEndpoint, FlowEndpointKind, app, bridge, device, deviceInput, deviceOutput

### Community 131 - "OscServer"
Cohesion: 0.36
Nodes (6): OscServer, Bool, Int, NWConnection, NWListener, Void

### Community 132 - "TLSW"
Cohesion: 0.25
Nodes (8): TLSW, ledOutputColour, offColour, onColour, pressedValue, releasedValue, switchMode, switchStatus

### Community 133 - "proto_cmc.rs"
Cohesion: 0.33
Nodes (3): BinarySerde, DeviceAdvertisement, DeviceId

### Community 134 - "SwiftUI"
Cohesion: 0.10
Nodes (14): AppLanguageStore, LanguagePicker, Badge, Bool, Color, Grid, gridAccent(), gridGray() (+6 more)

### Community 135 - "AppInfo"
Cohesion: 0.48
Nodes (4): AppInfo, AppsPayload, SetAppCapturePayload, Int32

### Community 136 - "bridges_install.sh"
Cohesion: 0.53
Nodes (5): ALL, fail(), log(), selected(), bridges_install.sh script

### Community 138 - "StripInfo"
Cohesion: 0.47
Nodes (4): InsertRowView, Int, StripInfo, StripsPayload

### Community 139 - "build_installer.sh"
Cohesion: 0.70
Nodes (4): build_installer_for_arch(), fail(), log(), build_installer.sh script

### Community 140 - "render"
Cohesion: 0.60
Nodes (4): _lerp(), main(), Render the Hydra mark at resolution S×S (RGBA, transparent corners)., render()

### Community 141 - "NetworkUtils.swift"
Cohesion: 0.40
Nodes (4): NetworkUtils, Set, String, SystemConfiguration

### Community 142 - "CHLCD"
Cohesion: 0.40
Nodes (5): CHLCD, channelName, ledColourOutput, mode, text

### Community 143 - "build_pkg.sh"
Cohesion: 0.83
Nodes (3): fail(), log(), build_pkg.sh script

### Community 144 - "DanteController/postinstall"
Cohesion: 0.83
Nodes (3): postinstall script, launch_dc(), log_postinstall()

### Community 146 - "ConnectionState"
Cohesion: 0.50
Nodes (4): ConnectionState, connected, connecting, disconnected

### Community 147 - "SlotsCtl"
Cohesion: 0.50
Nodes (4): SlotsCtl, currentSlotSel, refreshCurrentSel, slotAssignments

### Community 149 - "set_current_thread_realtime"
Cohesion: 0.50
Nodes (3): Error, Result, set_current_thread_realtime()

### Community 150 - "HydraApp"
Cohesion: 0.67
Nodes (3): App, HydraApp, Scene

## Knowledge Gaps
- **416 isolated node(s):** `Script-5523C934D0F4E104405D721B.sh script`, `Script-C641665DE93AF2886FB53446.sh script`, `ResourceBundleClass`, `DeveloperToolsSupport.ColorResource`, `DeveloperToolsSupport.ImageResource` (+411 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **97 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `DeviceInfo`, `FlowsTransmitter`, `DeviceMDNSResponder`, `TransmitMulticasts`, `channels_subscriber.rs`, `Cow`, `NodeKind`, `Kind`, `Service`, `run_server`, `CodingKeys`, `SubObject`, `MdnsClient`, `MetricsReporter`?**
  _High betweenness centrality (0.317) - this node is a cross-community bridge._
- **Why does `DeviceInfo` connect `DeviceInfo` to `FlowsTransmitter`, `DeviceMDNSResponder`, `TransmitMulticasts`, `run_server`, `proto_arc.rs`, `channels_subscriber.rs`, `String`, `run_server`, `DeviceServer`, `.new`, `run_server`, `flows_rx.rs`, `MdnsClient`, `.new_realtime`?**
  _High betweenness centrality (0.163) - this node is a cross-community bridge._
- **Why does `NodeKind` connect `NodeKind` to `SidebarTab`, `Sendable`, `String`?**
  _High betweenness centrality (0.110) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `DaemonClient` (e.g. with `Aes67Payload` and `ChannelLabelsPayload`) actually correct?**
  _`DaemonClient` has 6 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Script-5523C934D0F4E104405D721B.sh script`, `Script-C641665DE93AF2886FB53446.sh script`, `ResourceBundleClass` to the rest of the system?**
  _416 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ring_buffer.rs` be split into smaller, more focused modules?**
  _Cohesion score 0.05622710622710623 - nodes in this community are weakly interconnected._
- **Should `Hydra.c` be split into smaller, more focused modules?**
  _Cohesion score 0.08622620380739082 - nodes in this community are weakly interconnected._