# Graph Report - .  (2026-07-20)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 3930 nodes · 9479 edges · 261 communities (185 shown, 76 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 491 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `76a0f92e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Hydra.c
- WSMessage
- ProcessTapManager
- DaemonClient
- Hydra
- Kind
- StripManager
- channels_subscriber.rs
- Sendable
- Foundation
- String
- String
- MatrixStore
- OSCMessage
- GridView
- proto_arc.rs
- CodingKeys
- CoreMIDIBackend
- View
- BroadcasterHandle
- Service
- DeviceServer
- flows_rx.rs
- Aes67ParserExtraTests
- SharedPluginHost
- Value
- Aes67Manager
- HiQnet
- ModuleManager
- ring_buffer.rs
- Int
- SurfaceBridge
- Discovery
- TransmitMulticasts
- DeviceInfo
- View
- RouteManager
- NdiManager
- Result
- .start
- Updater
- ChannelRing
- ResponderMemoryEntry
- BridgeManager
- T
- PluginHost
- PtpClock
- InstallerState
- FlowsTransmitter
- .emit
- ClockOverlay
- FlowChainCard
- Aes67Tx
- InstallerWindowDelegate
- .new
- SettingsView.swift
- GridEntry
- run_server
- PolyphaseResampler
- PtpParsingTests
- DeviceManager
- .start
- .pairs
- SurfaceManager
- MdnsClient
- AppInfo
- SidebarView
- MetricsReporter
- InstallManager
- Aes67Stream
- MenuBarPanel.swift
- ResampleServoTests
- DeviceMDNSResponder
- DiscoveryBuilder
- RealTimeSamplesReceiver
- ExternalBuffer<T>
- run_server
- HiQnetServer
- bytes.rs
- Cow
- flows_tx.rs
- AppDelegate
- String
- DanteClockBrowser
- log
- UdpSocketWrapper
- PatchPoint
- Message
- media_clock.rs
- .impl_run
- InfernoManager
- SwiftUI
- DeviceOutputTap
- Component
- .backplaneDeviceID
- InterfaceStore
- ComponentStatus
- CodingKeys
- MediaClock
- hydra_ndi.c
- HydraEvent
- Headers/hydra_plugin_shm.h
- ChannelsSubscriberInternal<P, B>
- BroadcasterBuilder
- AppKit
- loopback_trx.rs
- Connection
- Context
- EnginePresence
- wrapped_diff
- .new_realtime
- PositionReportDestination
- .menuBarWave
- DataType
- AudioEngine
- Connection
- include/hydra_plugin_shm.h
- HiQnetDiscovery
- samples_utils.rs
- make_channel_change_notification
- RealTimeBoxReceiver
- CommandPalette
- common.rs
- run_server
- Flow
- DanteClockBrowser
- DanteClockBrowser
- build_and_install.sh
- Coordinator
- release.sh
- run_future_in_new_thread
- hydra-plugin-host.build/DerivedSources/GeneratedAssetSymbols.swift
- install_local.sh
- GFAD
- SubObject
- ContentView
- generate_xcodeproj.rb
- Diagnostics
- StripGridView.swift
- TLSW
- MultiIpIoError
- WindowAccessor
- Theme.swift
- PatchScene
- bridges_install.sh
- NodeKind
- peaks_of_buffers
- proto_cmc.rs
- RBOutput<T, P>
- build_installer.sh
- render
- NetworkUtils.swift
- CHLCD
- iface_v6_name_to_index
- build_pkg.sh
- SlotsCtl
- main.rs
- Option
- set_current_thread_realtime
- PackageDescription
- bridges_uninstall.sh
- fetch_vst3sdk.sh
- install_and_test.sh
- postinstall
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
- Option
- Receiver
- SocketAddr
- UdpSocket
- BTreeSet
- Error
- NonZeroU32
- Vec
- FlowEndpointKind

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
- `StripGridView` --references--> `View`  [EXTRACTED]
  Sources/HydraApp/StripGridView.swift → Sources/HydraApp/MenuBarPanel.swift
- `MatrixStore` --calls--> `PatchMatrix`  [INFERRED]
  Sources/hydrad/MatrixStore.swift → Sources/HydraCore/PatchMatrix.swift
- `SurfaceManager` --calls--> `SurfaceBridge`  [INFERRED]
  Sources/hydrad/SurfaceManager.swift → Sources/HydraSurface/SurfaceBridge.swift

## Import Cycles
- 2-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/channels_subscriber.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_rx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/channels_subscriber.rs`
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/mdns_server.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/tx_multicasts.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 4-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/tx_multicasts.rs -> Sources/Inferno/inferno_aoip/src/device_server/mdns_server.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`

## Communities (261 total, 76 thin omitted)

### Community 0 - "Hydra.c"
Cohesion: 0.09
Nodes (85): AudioObjectPropertyAddress, AudioServerPlugInClientInfo, AudioServerPlugInDriverRef, AudioServerPlugInHostRef, AudioServerPlugInIOCycleInfo, BlackHole_AbortDeviceConfigurationChange(), BlackHole_AddDeviceClient(), BlackHole_AddRef() (+77 more)

### Community 1 - "WSMessage"
Cohesion: 0.03
Nodes (80): Aes67Payload, Encoder, LevelsPayload, MatrixPayload, SceneRefPayload, ScenesPayload, Connection, Float (+72 more)

### Community 2 - "ProcessTapManager"
Cohesion: 0.06
Nodes (34): AudioObjectPropertySelector, NSRunningApplication, ResponsibleFn, ConnectionIndex, Gain, PatchMatrix, Bool, Connection (+26 more)

### Community 3 - "DaemonClient"
Cohesion: 0.07
Nodes (23): GridEntry, Observation, ConnectionState, connected, connecting, disconnected, ConnMeters, DaemonClient (+15 more)

### Community 4 - "Hydra"
Cohesion: 0.06
Nodes (16): Float, BridgeSpec, Hydra, SurfacePreset, Bool, Int, String, PatchValidation (+8 more)

### Community 5 - "Kind"
Cohesion: 0.03
Nodes (68): Kind, aes67, applyScene, apps, bridges, config, connectSurfaceConsole, createInterface (+60 more)

### Community 6 - "StripManager"
Cohesion: 0.07
Nodes (34): InsertRowView, Int, StripInfo, StripsPayload, VSTChainInfo, VSTPayload, VSTPlugin, ChainTap (+26 more)

### Community 7 - "channels_subscriber.rs"
Cohesion: 0.09
Nodes (43): ChannelOtherEnd, ChannelsBuffering, ChannelsSubscriber, ChannelsSubscriberInternal, ChannelSubscription, Command, ExternalBuffering, Flow (+35 more)

### Community 8 - "Sendable"
Cohesion: 0.10
Nodes (34): Codable, Equatable, Identifiable, Sendable, BridgeInfo, BridgeRole, both, input (+26 more)

### Community 9 - "Foundation"
Cohesion: 0.09
Nodes (14): Accelerate, AVFoundation, CoreAudio, Foundation, HydraCore, HydraNDIShim, HydraRT, HydraSurface (+6 more)

### Community 10 - "String"
Cohesion: 0.07
Nodes (25): CaseIterable, PluginPickerSheet, StripInfo, ViewMode, category, flat, vendor, PluginCategory (+17 more)

### Community 11 - "String"
Cohesion: 0.10
Nodes (26): Decoder, Double, ChannelLabelsPayload, ChannelScope, input, output, ConfigPayload, CreateInterfacePayload (+18 more)

### Community 12 - "MatrixStore"
Cohesion: 0.10
Nodes (23): AudioBufferList, ContiguousArray, os_unfair_lock, Snapshot, Conn, EngineTap, InMeter, MatrixStore (+15 more)

### Community 13 - "OSCMessage"
Cohesion: 0.10
Nodes (18): OSCArg, float, int, string, OSCMessage, OSCParser, Data, Float (+10 more)

### Community 14 - "GridView"
Cohesion: 0.10
Nodes (26): Axis, Bool, CGFloat, CGRect, CGSize, GeometryEffect, GraphicsContext, GroupDef (+18 more)

### Community 15 - "proto_arc.rs"
Cohesion: 0.07
Nodes (34): InItem, Iterator, OutItem, ChannelDescriptor, common_channels_descriptor_new_matches_device_info(), CommonChannelsDescriptor, Descriptor2, deserialize_items() (+26 more)

### Community 16 - "CodingKeys"
Cohesion: 0.04
Nodes (48): CodingKeys, aes67TX, appTapMakeupDB, backplaneDeviceName, backplaneInstalled, base, category, channelIndex (+40 more)

### Community 17 - "CoreMIDIBackend"
Cohesion: 0.08
Nodes (29): Addr, BTreeSet, CoreMIDI, CustomStringConvertible, Error, Ipv6Addr, MIDIEndpointRef, MIDIPacketList (+21 more)

### Community 18 - "View"
Cohesion: 0.10
Nodes (32): BridgeInfo, BridgeRole, ChannelFocus, ChannelScope, Color, ConnMeters, DaemonClient, Font (+24 more)

### Community 19 - "BroadcasterHandle"
Cohesion: 0.14
Nodes (14): IntoName, BroadcasterHandle, BroadcasterHandleDrop, BroadcasterHandleInner, Arc, Drop, F, JoinHandle (+6 more)

### Community 20 - "Service"
Cohesion: 0.08
Nodes (21): DnsMessage, IpAddr, Ord, Ordering, PartialOrd, Borrow, BTreeSet, Deref (+13 more)

### Community 21 - "DeviceServer"
Cohesion: 0.11
Nodes (29): Fn, DeviceServer, Arc, Atomic, AtomicUsize, B, Box, BTreeMap (+21 more)

### Community 22 - "flows_rx.rs"
Cohesion: 0.13
Nodes (29): AtomicI32, Poll, Channel, Command, FlowInfo, FlowsReceiver, FlowsReceiver<P>, FlowsReceiverInternal (+21 more)

### Community 23 - "Aes67ParserExtraTests"
Cohesion: 0.10
Nodes (10): SDPParser, Data, Aes67ParserExtraTests, Data, Int, UInt8, Aes67Tests, Bool (+2 more)

### Community 24 - "SharedPluginHost"
Cohesion: 0.12
Nodes (19): ChainHandle, ChainSpec, SharedPluginHost, Any, Bool, DispatchSourceTimer, Double, Float (+11 more)

### Community 25 - "Value"
Cohesion: 0.08
Nodes (26): Int16, Int8, Binding, Bool, DispatchWorkItem, TimeInterval, Void, SyncedValue (+18 more)

### Community 26 - "Aes67Manager"
Cohesion: 0.11
Nodes (18): NWBrowser, Aes67Manager, Aes67Rx, MulticastReceiver, Bool, Data, Date, DispatchSourceRead (+10 more)

### Community 27 - "HiQnet"
Cohesion: 0.19
Nodes (11): Address, Array, Flags, Frame, HiQnet, Subscription, Int, UInt32 (+3 more)

### Community 28 - "ModuleManager"
Cohesion: 0.12
Nodes (20): CChar, HydraModule, HydraModuleABI, moduleHostDeliver(), moduleHostLog(), moduleHostSourcesChanged(), ModuleManager, ModuleRx (+12 more)

### Community 29 - "ring_buffer.rs"
Cohesion: 0.18
Nodes (30): ExactSizeIterator, for_in_ring(), new_owned(), non_sequential_write_single_read(), ReadResult, FnMut, Item, test_close_items_until_after_reset() (+22 more)

### Community 30 - "Int"
Cohesion: 0.10
Nodes (20): Int, Decoder, Event, fader, ping, scribble, switchState, HUI (+12 more)

### Community 31 - "SurfaceBridge"
Cohesion: 0.15
Nodes (13): AnyObject, Never, MIDIBackend, Config, SlotKey, SurfaceBridge, Bool, Int (+5 more)

### Community 32 - "Discovery"
Cohesion: 0.19
Nodes (17): DnsRecordType, Discovery, discovery_packet(), DiscoveryHandle, query_packet(), DnsName, DnsResponse, Duration (+9 more)

### Community 33 - "TransmitMulticasts"
Cohesion: 0.12
Nodes (23): Bundle, Arc, AtomicBool, AtomicU32, BTreeMap, Error, Ipv4Addr, Mutex (+15 more)

### Community 34 - "DeviceInfo"
Cohesion: 0.11
Nodes (25): MacAddr, Channel, DeviceInfo, dummy_device_info(), five_ms_at_48000_hz(), large_values_no_overflow(), one_second_at_44100_hz(), one_second_at_48000_hz() (+17 more)

### Community 35 - "View"
Cohesion: 0.09
Nodes (14): AboutView, LocalizedStringKey, View, SurfaceConfigSheet, Int, Bool, Void, WelcomeSheet (+6 more)

### Community 36 - "RouteManager"
Cohesion: 0.16
Nodes (12): BridgeManager, DeviceManager, DeviceOutputTap, MatrixStore, FlowInfo, RouteManager, Bool, PatchPoint (+4 more)

### Community 37 - "NdiManager"
Cohesion: 0.14
Nodes (13): NdiManager, NdiRx, NdiTx, Bool, DispatchSourceTimer, Double, Float, Int (+5 more)

### Community 38 - "Result"
Cohesion: 0.14
Nodes (18): Copy, Iface, Socket, InterfacedMdnsSocket, InterfacedMdnsSocket<AsyncUdpSocket, Iface>, InterfacedMdnsSocket<Socket, Iface>, InterfacedMdnsSocket<UdpSocket, Iface>, MdnsSocket (+10 more)

### Community 39 - ".start"
Cohesion: 0.10
Nodes (13): DispatchQueue, DaemonContext, DispatchSourceTimer, OscServer, Bool, Int, NWConnection, NWListener (+5 more)

### Community 40 - "Updater"
Cohesion: 0.13
Nodes (17): Decodable, GHAsset, GHRelease, Release, Bool, Data, Error, TimeInterval (+9 more)

### Community 41 - "ChannelRing"
Cohesion: 0.17
Nodes (14): Bool, ABLUtil, ChannelRing, Bool, Double, Float, Int, Int64 (+6 more)

### Community 42 - "ResponderMemoryEntry"
Cohesion: 0.10
Nodes (20): Cell, Hash, HashSet, DiscoveryEvent, Arc, Responder, ResponderMemory, ResponderMemoryEntry (+12 more)

### Community 43 - "BridgeManager"
Cohesion: 0.16
Nodes (11): BridgeManager, Persisted, PresentBridge, AudioObjectID, Bool, DispatchWorkItem, Double, Int (+3 more)

### Community 44 - "T"
Cohesion: 0.20
Nodes (19): ExternalBuffer, ExternalBufferParameters, ExternalRBInput, ExternalRBOutput, RBInput, RBInput<T, P>, RBOutput, RingBufferShared (+11 more)

### Community 45 - "PluginHost"
Cohesion: 0.14
Nodes (15): Darwin, HydraPluginHostABI, ChainCommand, ChainManager, hlog(), PluginHost, PluginSpec, Data (+7 more)

### Community 46 - "PtpClock"
Cohesion: 0.22
Nodes (12): Master, PtpClock, PtpStatus, Snapshot, Data, DispatchSourceTimer, Double, Int (+4 more)

### Community 47 - "InstallerState"
Cohesion: 0.11
Nodes (12): FooterView, Bool, InstallerState, InstallerStep, complete, install, license, selection (+4 more)

### Community 48 - "FlowsTransmitter"
Cohesion: 0.15
Nodes (13): FlowInfo, FlowsTransmitter, AtomicU32, BTreeMap, Error, FlowHandle, IntoIterator, Ipv4Addr (+5 more)

### Community 49 - ".emit"
Cohesion: 0.14
Nodes (14): AVAudioFile, AVAudioPCMBuffer, EventCenter, HydraEvent, String, Void, Recording, RecordingManager (+6 more)

### Community 50 - "ClockOverlay"
Cohesion: 0.14
Nodes (15): c_int, ClockId, AsyncClient, clock_now_ns(), ClockOverlay, errno(), now_computations(), JoinHandle (+7 more)

### Community 51 - "FlowChainCard"
Cohesion: 0.17
Nodes (8): FlowInfo, PhysicalDeviceInfo, FlowChainCard, FluxView, Bool, Int, String, DeviceDetailView

### Community 52 - "Aes67Tx"
Cohesion: 0.13
Nodes (15): Aes67Tx, Aes67TxManager, localIPv4Address(), Bool, DispatchSourceTimer, Double, Float, Int (+7 more)

### Community 53 - "InstallerWindowDelegate"
Cohesion: 0.11
Nodes (17): App, NSApplicationDelegate, NSObject, NSWindowDelegate, HydraApp, Scene, AppDelegate, HydraInstallerApp (+9 more)

### Community 54 - ".new"
Cohesion: 0.23
Nodes (17): AtomicU16, FlowControlError, FlowsControlClient, minimal_device_info(), Arc, Box, ByteBuffer, Error (+9 more)

### Community 55 - "SettingsView.swift"
Cohesion: 0.11
Nodes (19): ChannelLabelsPayload, Date, PatchScene, AdvancedSettingsPane, AudioSettingsPane, ControlSettingsPane, GeneralSettingsPane, PluginRow (+11 more)

### Community 56 - "GridEntry"
Cohesion: 0.18
Nodes (11): PatchPoint, DeviceViewPatch, SignalDotPublic, Binding, Bool, CGFloat, Color, Int (+3 more)

### Community 57 - "run_server"
Cohesion: 0.14
Nodes (20): Serialize, Arc, BroadcastReceiver, Mutex, Option, Receiver, Sender, run_server() (+12 more)

### Community 58 - "PolyphaseResampler"
Cohesion: 0.19
Nodes (6): PolyphaseResampler, ArraySlice, Double, Float, Int, PolyphaseResamplerTests

### Community 59 - "PtpParsingTests"
Cohesion: 0.13
Nodes (7): PtpParsing, ArraySlice, Bool, Double, Int, UInt8, PtpParsingTests

### Community 60 - "DeviceManager"
Cohesion: 0.16
Nodes (13): DeviceIO, DeviceManager, Present, AudioDeviceIOProcID, AudioObjectID, Bool, Double, Float (+5 more)

### Community 61 - ".start"
Cohesion: 0.14
Nodes (16): JoinError, OverlayReceiveError, blocking_send_recv(), BlockingClient, client_socket_path(), Box, Drop, FnMut (+8 more)

### Community 62 - ".pairs"
Cohesion: 0.11
Nodes (12): destination, ChannelPairing, formatElapsed(), LoadSeverity, critical, elevated, normal, Double (+4 more)

### Community 63 - "SurfaceManager"
Cohesion: 0.15
Nodes (6): DaemonContext, DaemonRuntime, Bool, SurfaceManager, DispatchSourceTimer, Void

### Community 64 - "MdnsClient"
Cohesion: 0.24
Nodes (14): RecordType, MdnsClient, Arc, Box, BTreeMap, DnsResponse, Duration, Error (+6 more)

### Community 65 - "AppInfo"
Cohesion: 0.43
Nodes (4): AppInfo, AppsPayload, SetAppCapturePayload, Int32

### Community 66 - "SidebarView"
Cohesion: 0.08
Nodes (23): Aes67Stream, AppInfo, Content, LocalizedStringKey, ModuleSourceInfo, NdiSourceInfo, Color, AppCaptureDetailView (+15 more)

### Community 67 - "MetricsReporter"
Cohesion: 0.13
Nodes (16): Logger, MXDiagnosticPayload, MXMetricManagerSubscriber, MXMetricPayload, MetricsReporter, Data, URL, Category (+8 more)

### Community 68 - "InstallManager"
Cohesion: 0.16
Nodes (13): Pipe, InstallManager, InstallResult, failure, success, Phase, failed, idle (+5 more)

### Community 69 - "Aes67Stream"
Cohesion: 0.23
Nodes (12): Aes67Device, Aes67Payload, Aes67Stream, Aes67TxInfo, Announcement, SAPParser, SubscribeStreamPayload, Bool (+4 more)

### Community 70 - "MenuBarPanel.swift"
Cohesion: 0.11
Nodes (13): Carbon, Commands, Notification.Name, UpdateCommands, AboutCommands, Font, MBSectionHeader, MBStatTile (+5 more)

### Community 71 - "ResampleServoTests"
Cohesion: 0.15
Nodes (5): ResampleServo, Bool, Double, Int, ResampleServoTests

### Community 72 - "DeviceMDNSResponder"
Cohesion: 0.18
Nodes (13): DeviceMDNSResponder, in_addr_type(), kv(), multicast_ip_to_name(), Arc, BTreeMap, Ipv4Addr, Name (+5 more)

### Community 73 - "DiscoveryBuilder"
Cohesion: 0.16
Nodes (9): DiscoveryBuilder, Default, DnsName, Duration, Option, Result, Self, TargetInterfaceV4 (+1 more)

### Community 74 - "RealTimeSamplesReceiver"
Cohesion: 0.22
Nodes (16): Channel, Command, get_min_max_end_timestamps(), PeriodicSamplesCollector, RealTimeSamplesReceiver, IntoIterator, Item, Option (+8 more)

### Community 75 - "ExternalBuffer<T>"
Cohesion: 0.17
Nodes (10): ExternalBuffer<Atomic<Sample>>, ExternalBuffer<T>, ExternalBufferParameters<T>, OwnedBuffer<Atomic<Sample>>, ProxyToBuffer, ProxyToSamplesBuffer, RingBufferShared<Sample, P>, Sample (+2 more)

### Community 76 - "run_server"
Cohesion: 0.23
Nodes (10): PeaksCallback, Multicaster, Multicaster<'s>, Arc, BroadcastReceiver, Option, Receiver, RwLock (+2 more)

### Community 77 - "HiQnetServer"
Cohesion: 0.19
Nodes (8): HiQnetServer, MeterListener, Bool, NWConnection, NWListener, UInt16, UInt8, Void

### Community 78 - "bytes.rs"
Cohesion: 0.16
Nodes (13): align_wpos(), ByteBuffer, Option, test_align_wpos_various_alignments(), test_write_0term_str_or_0_to_bytebuffer_some_and_none(), test_write_0term_str_to_bytebuffer_offset_and_trailing_zero(), test_write_str_to_buffer_empty_string(), test_write_str_to_buffer_exact_fit() (+5 more)

### Community 79 - "Cow"
Cohesion: 0.18
Nodes (7): Cow, Sized, IntoServiceTxt, &'static str, &'static [u8], &'static [u8; N], Vec<u8>

### Community 80 - "flows_tx.rs"
Cohesion: 0.22
Nodes (16): LongClockDiff, SmallRng, Command, FlowData, FlowsTransmitterInternal, Arc, AtomicBool, AtomicUsize (+8 more)

### Community 81 - "AppDelegate"
Cohesion: 0.19
Nodes (7): ObservableObject, DaemonService, AppDelegate, Bool, Notification, NSApplication, NSWindow

### Community 82 - "String"
Cohesion: 0.21
Nodes (10): ChannelSettings, Arc, Channel, Self, Vec, SavedChannels, SavedChannelsSettings, get_chromecast_name() (+2 more)

### Community 83 - "DanteClockBrowser"
Cohesion: 0.16
Nodes (10): NetService, NetServiceBrowser, NetServiceBrowserDelegate, NetServiceDelegate, NSNumber, DanteClockBrowser, Bool, Data (+2 more)

### Community 84 - "log"
Cohesion: 0.23
Nodes (9): NWParameters, ObjectIdentifier, log(), Bool, NWConnection, NWListener, UInt16, Void (+1 more)

### Community 85 - "UdpSocketWrapper"
Cohesion: 0.22
Nodes (11): Option, Receiver, SocketAddr, create_mio_udp_socket(), create_tokio_udp_socket(), ReceiveBuffer, Ipv4Addr, Result (+3 more)

### Community 86 - "PatchPoint"
Cohesion: 0.19
Nodes (8): OptionSet, Channel, Node, NodeDirections, PatchPoint, Bool, Channel, Int

### Community 87 - "Message"
Cohesion: 0.11
Nodes (18): Message, discoInfo, getAttributes, getNetworkInfo, getVDList, goodbye, hello, multiObjectParamSet (+10 more)

### Community 88 - "media_clock.rs"
Cohesion: 0.18
Nodes (12): async_clock_receiver_to_realtime(), make_shared_media_clock(), media_clock_new_not_ready(), media_clock_update_overlay_becomes_ready(), media_clock_update_overlay_replaces(), Arc, ClockReceiver, PathBuf (+4 more)

### Community 89 - ".impl_run"
Cohesion: 0.21
Nodes (12): AsyncUdpSocket, Broadcaster, BroadcasterConfig, Arc, BTreeSet, Option, Receiver, Result (+4 more)

### Community 90 - "InfernoManager"
Cohesion: 0.20
Nodes (8): ConfigPayload, Int32, Process, InfernoManager, Bool, Int, String, URL

### Community 91 - "SwiftUI"
Cohesion: 0.13
Nodes (8): AppLanguageStore, LanguagePicker, Badge, Bool, Color, ContentView, LicenseView, SwiftUI

### Community 92 - "DeviceOutputTap"
Cohesion: 0.23
Nodes (9): CATapDescription, DeviceOutputTap, AudioDeviceIOProcID, AudioObjectID, Double, Float, Int, UInt32 (+1 more)

### Community 93 - "Component"
Cohesion: 0.14
Nodes (12): Hashable, Component, ComponentCatalog, Bool, Double, ComponentInstallRow, InstallView, Bool (+4 more)

### Community 94 - ".backplaneDeviceID"
Cohesion: 0.28
Nodes (6): BackplaneProbe, AudioObjectID, AudioObjectPropertyScope, Bool, Double, Int

### Community 95 - "InterfaceStore"
Cohesion: 0.24
Nodes (6): InterfaceStore, Bool, Connection, Int, Range, UUID

### Community 96 - "ComponentStatus"
Cohesion: 0.22
Nodes (11): AppleScriptResult, InstallerEngine, Bool, Double, Void, ComponentStatus, failed, installed (+3 more)

### Community 97 - "CodingKeys"
Cohesion: 0.13
Nodes (15): CodingKey, CodingKeys, address, aes67On, channels, devices, flowIndex, interfaceID (+7 more)

### Community 98 - "MediaClock"
Cohesion: 0.25
Nodes (8): FineClock, MediaClock, Clock, Duration, LongClock, Option, timestamp_to_clock_value(), Timestamp

### Community 99 - "hydra_ndi.c"
Cohesion: 0.14
Nodes (4): hndi_source_t, hndi_find_sources(), hndi_load(), try_dlopen()

### Community 100 - "HydraEvent"
Cohesion: 0.17
Nodes (11): Color, HydraEvent, Kind, error, info, installed, resourceLost, resourceRestored (+3 more)

### Community 101 - "Headers/hydra_plugin_shm.h"
Cohesion: 0.18
Nodes (7): hydra_plugin_cmd, hydra_plugin_shm, hydra_plugin_shm_bytes(), hydra_plugin_shm_cmd(), hydra_plugin_shm_input(), hydra_plugin_shm_output(), hydra_plugin_shm_slot_floats()

### Community 102 - "ChannelsSubscriberInternal<P, B>"
Cohesion: 0.27
Nodes (4): ChannelsSubscriberInternal<P, B>, Flow<P>, IntoIterator, Item

### Community 103 - "BroadcasterBuilder"
Cohesion: 0.22
Nodes (7): BroadcasterBuilder, BTreeSet, Default, Result, Self, TargetInterfaceV4, TargetInterfaceV6

### Community 104 - "AppKit"
Cohesion: 0.18
Nodes (6): AppKit, Combine, CryptoKit, HydraDaemon, os, ServiceManagement

### Community 105 - "loopback_trx.rs"
Cohesion: 0.22
Nodes (13): AtomicSample, compare_samples(), find_samples_offset(), make_settings(), Arc, AtomicBool, JoinHandle, Option (+5 more)

### Community 106 - "Connection"
Cohesion: 0.26
Nodes (6): BinarySerde, Connection, make_packet(), RemoteInfo, Option, SocketAddr

### Community 107 - "Context"
Cohesion: 0.23
Nodes (7): Context, NSClickGestureRecognizer, NSGestureRecognizerRepresentable, NSSearchField, NSVisualEffectView, RightClickGesture, VisualEffectView

### Community 108 - "EnginePresence"
Cohesion: 0.19
Nodes (7): EnginePresence, noBackplane, offline, running, stopped, Bool, EnginePresenceTests

### Community 109 - "wrapped_diff"
Cohesion: 0.22
Nodes (7): Clock, ClockDiff, wrapped_diff(), Channel<P>, PeriodicSamplesCollector<P>, RealTimeSamplesReceiver<P>, Clock

### Community 110 - ".new_realtime"
Cohesion: 0.23
Nodes (9): Arc, Box, Future, Output, Pin, SamplesCallback, Self, Send (+1 more)

### Community 111 - "PositionReportDestination"
Cohesion: 0.12
Nodes (10): ExternalRBInput<T>, OwnedBuffer<T>, PositionReportDestination, RingBufferShared<T, P>, AtomicUsize, FnOnce, Option, R (+2 more)

### Community 112 - ".menuBarWave"
Cohesion: 0.23
Nodes (10): CGPoint, NSImage, Path, Shape, MenuBarStatusLabel, BrandMark, IconPack, CGFloat (+2 more)

### Community 113 - "DataType"
Cohesion: 0.15
Nodes (13): DataType, block, byte, float32, float64, long, long64, string (+5 more)

### Community 114 - "AudioEngine"
Cohesion: 0.24
Nodes (9): AudioObjectPropertyListenerBlock, HydraSignpost, AudioEngine, EngineMetrics, AudioDeviceIOProcID, AudioObjectID, Bool, Double (+1 more)

### Community 115 - "Connection"
Cohesion: 0.23
Nodes (3): Connection, Float, ModelsTests

### Community 116 - "include/hydra_plugin_shm.h"
Cohesion: 0.24
Nodes (7): hydra_plugin_cmd, hydra_plugin_shm, hydra_plugin_shm_bytes(), hydra_plugin_shm_cmd(), hydra_plugin_shm_input(), hydra_plugin_shm_output(), hydra_plugin_shm_slot_floats()

### Community 117 - "HiQnetDiscovery"
Cohesion: 0.30
Nodes (5): HiQnetDiscovery, DispatchSourceRead, Int32, UInt8, Void

### Community 119 - "make_channel_change_notification"
Cohesion: 0.23
Nodes (10): make_channel_change_notification(), make_channel_change_notification_empty_iterator(), make_channel_change_notification_returns_start_code_and_opcode(), make_packet(), make_packet_produces_correct_header_bytes(), make_packet_total_length_equals_header_length_plus_content_len(), IntoIterator, Item (+2 more)

### Community 120 - "RealTimeBoxReceiver"
Cohesion: 0.33
Nodes (8): AtomicOptionBox, channel(), RealTimeBoxReceiver, RealTimeBoxSender, RealTimeBoxSender<T>, Arc, Box, Shared

### Community 121 - "CommandPalette"
Cohesion: 0.24
Nodes (7): Element, Array, CommandPalette, PaletteAction, Bool, Int, Void

### Community 122 - "common.rs"
Cohesion: 0.22
Nodes (4): log_and_forget_err(), log_and_forget_ok(), LogAndForget, Result<T, E>

### Community 123 - "run_server"
Cohesion: 0.22
Nodes (10): Arc, BroadcastReceiver, Mutex, Option, run_server(), make_u16(), read_0term_str_from_buffer(), Box (+2 more)

### Community 124 - "Flow"
Cohesion: 0.38
Nodes (5): Flow, FlowsTransmitterInternal<P>, Clock, LongClock, UdpSocket

### Community 125 - "DanteClockBrowser"
Cohesion: 0.18
Nodes (10): DanteClockBrowser, -initOBJC_DESIGNATED_INITIALIZER, -netServiceBrowserdidFindServicemoreComing, -netServiceBrowserdidRemoveServicemoreComing, -netServicedidNotResolve, -netServiceDidResolveAddress, -netServicedidUpdateTXTRecordData, NSNetServiceBrowserDelegate (+2 more)

### Community 126 - "DanteClockBrowser"
Cohesion: 0.18
Nodes (10): DanteClockBrowser, -initOBJC_DESIGNATED_INITIALIZER, -netServiceBrowserdidFindServicemoreComing, -netServiceBrowserdidRemoveServicemoreComing, -netServicedidNotResolve, -netServiceDidResolveAddress, -netServicedidUpdateTXTRecordData, NSNetServiceBrowserDelegate (+2 more)

### Community 127 - "build_and_install.sh"
Cohesion: 0.60
Nodes (9): build_driver(), customize_source(), fail(), fetch_source(), install_driver(), log(), require_xcode(), build_and_install.sh script (+1 more)

### Community 128 - "Coordinator"
Cohesion: 0.29
Nodes (6): Binding, Notification, NSSearchFieldDelegate, Coordinator, SearchField, String

### Community 129 - "release.sh"
Cohesion: 0.29
Nodes (5): fail(), header(), note(), run(), release.sh script

### Community 130 - "run_future_in_new_thread"
Cohesion: 0.22
Nodes (9): Box, FnOnce, Future, JoinHandle, Output, Pin, Send, run_future_in_new_thread() (+1 more)

### Community 131 - "hydra-plugin-host.build/DerivedSources/GeneratedAssetSymbols.swift"
Cohesion: 0.22
Nodes (7): DeveloperToolsSupport, DeveloperToolsSupport.ColorResource, DeveloperToolsSupport.ImageResource, ResourceBundleClass, DeveloperToolsSupport.ColorResource, DeveloperToolsSupport.ImageResource, ResourceBundleClass

### Community 132 - "install_local.sh"
Cohesion: 0.58
Nodes (8): device_visible(), do_install(), do_status(), do_uninstall(), fail(), log(), restart_coreaudiod(), install_local.sh script

### Community 133 - "GFAD"
Cohesion: 0.22
Nodes (9): GFAD, enable, faderMode, faderUByteValue, faderValue, glowColour, glowFunction, motorUByteValue (+1 more)

### Community 134 - "SubObject"
Cohesion: 0.22
Nodes (8): SubObject, fader, lcd, onSw, selSw, soloSw, Bool, Int

### Community 135 - "ContentView"
Cohesion: 0.32
Nodes (4): NavigationSplitViewVisibility, ContentView, Binding, Bool

### Community 136 - "generate_xcodeproj.rb"
Cohesion: 0.36
Nodes (4): c_framework(), common!(), each_config(), sync_dir()

### Community 138 - "StripGridView.swift"
Cohesion: 0.36
Nodes (7): linearToDb(), MeterColumn, StripCardView, StripGridView, StripMeters, Color, Float

### Community 139 - "TLSW"
Cohesion: 0.25
Nodes (8): TLSW, ledOutputColour, offColour, onColour, pressedValue, releasedValue, switchMode, switchStatus

### Community 140 - "MultiIpIoError"
Cohesion: 0.09
Nodes (22): Display, Formatter, BroadcasterBuilderError, Error, ServiceBuilderError, ServiceDnsPacketBuilderError, DiscoveryBuilderError, DiscoveryHandleDrop (+14 more)

### Community 141 - "WindowAccessor"
Cohesion: 0.38
Nodes (5): NSView, NSViewRepresentable, Context, Void, WindowAccessor

### Community 142 - "Theme.swift"
Cohesion: 0.52
Nodes (6): Grid, gridAccent(), gridGray(), CGFloat, Color, Theme

### Community 144 - "bridges_install.sh"
Cohesion: 0.53
Nodes (5): ALL, fail(), log(), selected(), bridges_install.sh script

### Community 145 - "NodeKind"
Cohesion: 0.33
Nodes (6): NodeKind, aes67, app, backplane, physicalDevice, vst

### Community 146 - "peaks_of_buffers"
Cohesion: 0.40
Nodes (5): peaks_of_buffers(), Arc, P, Sample, Vec

### Community 149 - "build_installer.sh"
Cohesion: 0.70
Nodes (4): build_installer_for_arch(), fail(), log(), build_installer.sh script

### Community 150 - "render"
Cohesion: 0.60
Nodes (4): _lerp(), main(), Render the Hydra mark at resolution S×S (RGBA, transparent corners)., render()

### Community 151 - "NetworkUtils.swift"
Cohesion: 0.40
Nodes (4): NetworkUtils, Set, String, SystemConfiguration

### Community 152 - "CHLCD"
Cohesion: 0.40
Nodes (5): CHLCD, channelName, ledColourOutput, mode, text

### Community 153 - "iface_v6_name_to_index"
Cohesion: 0.50
Nodes (4): iface_v6_name_to_index(), Error, NonZeroU32, Result

### Community 154 - "build_pkg.sh"
Cohesion: 0.83
Nodes (3): fail(), log(), build_pkg.sh script

### Community 155 - "SlotsCtl"
Cohesion: 0.50
Nodes (4): SlotsCtl, currentSlotSel, refreshCurrentSel, slotAssignments

### Community 158 - "set_current_thread_realtime"
Cohesion: 0.50
Nodes (3): Error, Result, set_current_thread_realtime()

### Community 260 - "FlowEndpointKind"
Cohesion: 0.33
Nodes (6): FlowEndpointKind, app, bridge, device, deviceInput, deviceOutput

## Knowledge Gaps
- **404 isolated node(s):** `Script-5523C934D0F4E104405D721B.sh script`, `Script-C641665DE93AF2886FB53446.sh script`, `ResourceBundleClass`, `DeveloperToolsSupport.ColorResource`, `DeveloperToolsSupport.ImageResource` (+399 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **76 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `MdnsClient`, `CodingKeys`, `DeviceInfo`, `MetricsReporter`, `HydraEvent`, `TransmitMulticasts`, `SubObject`, `channels_subscriber.rs`, `DeviceMDNSResponder`, `Cow`, `FlowsTransmitter`, `NodeKind`, `Service`, `run_server`?**
  _High betweenness centrality (0.336) - this node is a cross-community bridge._
- **Why does `DeviceInfo` connect `DeviceInfo` to `MdnsClient`, `TransmitMulticasts`, `channels_subscriber.rs`, `DeviceMDNSResponder`, `run_server`, `.new_realtime`, `proto_arc.rs`, `FlowsTransmitter`, `flows_tx.rs`, `String`, `DeviceServer`, `flows_rx.rs`, `.new`, `run_server`, `run_server`?**
  _High betweenness centrality (0.175) - this node is a cross-community bridge._
- **Why does `NodeKind` connect `NodeKind` to `Sendable`, `String`, `String`, `PatchPoint`?**
  _High betweenness centrality (0.116) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `DaemonClient` (e.g. with `Aes67Payload` and `ChannelLabelsPayload`) actually correct?**
  _`DaemonClient` has 6 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Script-5523C934D0F4E104405D721B.sh script`, `Script-C641665DE93AF2886FB53446.sh script`, `ResourceBundleClass` to the rest of the system?**
  _404 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Hydra.c` be split into smaller, more focused modules?**
  _Cohesion score 0.08622620380739082 - nodes in this community are weakly interconnected._
- **Should `WSMessage` be split into smaller, more focused modules?**
  _Cohesion score 0.025712949976624593 - nodes in this community are weakly interconnected._