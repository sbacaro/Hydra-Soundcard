# Graph Report - .  (2026-07-20)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 3912 nodes · 9445 edges · 232 communities (187 shown, 45 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 497 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `64c881f7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Hydra.c
- WSMessage
- FlowsTransmitter
- DaemonClient
- ProcessTapManager
- TransmitMulticasts
- Sendable
- Hydra
- Kind
- OSCMessage
- PtpClock
- ClockOverlay
- Equatable
- Identifiable
- CodingKeys
- BroadcasterHandle
- Service
- DeviceServer
- String
- flows_rx.rs
- channels_subscriber.rs
- Aes67Manager
- VirtualInterfaceInfo
- HiQnet
- ring_buffer.rs
- HUI
- Foundation
- View
- GridView
- Value
- SurfaceBridge
- MultiIpIoError
- InstallerState
- View
- DeviceInfo
- RouteManager
- MatrixStore
- .start
- bytes.rs
- Result
- InstallManager
- Aes67ParserExtraTests
- ResponderMemoryEntry
- SidebarView
- NdiManager
- StripManager
- proto_arc.rs
- PluginHost
- SwiftUI
- BridgeManager
- .emit
- GridEntry
- Updater
- .pairs
- Component
- ChannelRing
- T
- .new
- SettingsView.swift
- PolyphaseResampler
- CoreMIDIBackend
- DeviceManager
- PoolTxTap
- SharedPluginHost
- Ipv6Interface
- GridView.swift
- ModuleRx
- MetricsReporter
- run_server
- DeviceOutputTap
- InstallerWindowDelegate
- ResampleServoTests
- DiscoveryBuilder
- ExternalBuffer<T>
- Snapshot
- run_server
- Aes67Stream
- ModuleManager
- ChainTap
- HydraRT
- MenuBarPanel.swift
- Cow
- ChainHandle
- RealTimeSamplesReceiver
- DanteClockBrowser
- log
- StateStorage
- Message
- HiQnetServer
- String
- media_clock.rs
- UdpSocketWrapper
- .impl_run
- InfernoManager
- SurfaceManager
- .backplaneDeviceID
- AppKit
- AudioEngine
- paginate_make_response
- FlowChainCard
- ExternalBuffering
- MediaClock
- hydra_ndi.c
- Headers/hydra_plugin_shm.h
- ChannelsSubscriberInternal<P, B>
- .new_realtime
- BroadcasterBuilder
- Connection
- Coordinator
- SidebarTab
- CodingKeys
- AppDelegate
- EnginePresence
- FlowEndpointKind
- PositionReportDestination
- .menuBarWave
- WindowAccessor
- DataType
- HydraApp/SidebarView.swift
- include/hydra_plugin_shm.h
- HiQnetDiscovery
- wrapped_diff
- common.rs
- Aes67Tests
- RealTimeBoxReceiver
- CommandPalette
- ContentView
- DanteClockBrowser
- DanteClockBrowser
- build_and_install.sh
- release.sh
- .shutdown
- hydra-plugin-host.build/DerivedSources/GeneratedAssetSymbols.swift
- install_local.sh
- GFAD
- SubObject
- DaemonService
- generate_xcodeproj.rb
- StripGridView.swift
- TLSW
- BridgeRole
- ShakeEffect
- bridges_install.sh
- peaks_of_buffers
- proto_cmc.rs
- RBOutput<T, P>
- build_installer.sh
- render
- NetworkUtils.swift
- CHLCD
- RecordingInfo
- build_pkg.sh
- EditorTarget
- SlotsCtl
- main.rs
- Option
- .new
- set_current_thread_realtime
- GHAsset
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
- Color
- Content
- FlowInfo
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
- Double
- Int32
- Process
- URL
- Void
- FlowInfo
- Self
- Vec

## God Nodes (most connected - your core abstractions)
1. `WSMessage` - 135 edges
2. `DaemonClient` - 83 edges
3. `Foundation` - 77 edges
4. `log()` - 71 edges
5. `Kind` - 70 edges
6. `MatrixStore` - 68 edges
7. `View` - 61 edges
8. `HydraCore` - 60 edges
9. `CodingKeys` - 57 edges
10. `StripManager` - 48 edges

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
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/tx_multicasts.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 3-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/mdns_server.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`
- 4-file cycle: `Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs -> Sources/Inferno/inferno_aoip/src/device_server/mod.rs -> Sources/Inferno/inferno_aoip/src/device_server/tx_multicasts.rs -> Sources/Inferno/inferno_aoip/src/device_server/mdns_server.rs -> Sources/Inferno/inferno_aoip/src/device_server/flows_tx.rs`

## Communities (232 total, 45 thin omitted)

### Community 0 - "Hydra.c"
Cohesion: 0.09
Nodes (85): AudioObjectPropertyAddress, AudioServerPlugInClientInfo, AudioServerPlugInDriverRef, AudioServerPlugInHostRef, AudioServerPlugInIOCycleInfo, BlackHole_AbortDeviceConfigurationChange(), BlackHole_AddDeviceClient(), BlackHole_AddRef() (+77 more)

### Community 1 - "WSMessage"
Cohesion: 0.03
Nodes (77): Aes67Payload, Encoder, EventsPayload, LevelsPayload, MatrixPayload, Connection, Float, HydraEvent (+69 more)

### Community 2 - "FlowsTransmitter"
Cohesion: 0.05
Nodes (56): AtomicSample, LongClockDiff, SmallRng, Command, Flow, FlowData, FlowInfo, FlowsTransmitter (+48 more)

### Community 3 - "DaemonClient"
Cohesion: 0.07
Nodes (24): GridEntry, Observation, Set, ConnectionState, connected, connecting, disconnected, ConnMeters (+16 more)

### Community 4 - "ProcessTapManager"
Cohesion: 0.06
Nodes (33): AudioObjectPropertySelector, NSRunningApplication, ResponsibleFn, ConnectionIndex, Gain, PatchMatrix, Bool, Connection (+25 more)

### Community 5 - "TransmitMulticasts"
Cohesion: 0.06
Nodes (50): RecordType, DeviceMDNSResponder, in_addr_type(), kv(), multicast_ip_to_name(), Arc, BTreeMap, Ipv4Addr (+42 more)

### Community 6 - "Sendable"
Cohesion: 0.12
Nodes (13): Sendable, SurfacePreset, Bool, AppInfo, AppsPayload, InterfacesPayload, SaveScenePayload, SceneRefPayload (+5 more)

### Community 7 - "Hydra"
Cohesion: 0.06
Nodes (15): Hydra, Double, Float, Int32, UInt16, URL, UUID, PatchValidation (+7 more)

### Community 8 - "Kind"
Cohesion: 0.03
Nodes (68): Kind, aes67, applyScene, apps, bridges, config, connectSurfaceConsole, createInterface (+60 more)

### Community 9 - "OSCMessage"
Cohesion: 0.08
Nodes (24): OSCArg, float, int, string, OSCMessage, OSCParser, Data, Float (+16 more)

### Community 10 - "PtpClock"
Cohesion: 0.09
Nodes (19): PtpParsing, ArraySlice, Bool, Double, Int, UInt8, Master, PtpClock (+11 more)

### Community 11 - "ClockOverlay"
Cohesion: 0.08
Nodes (31): c_int, ClockId, JoinError, OverlayReceiveError, AsyncClient, blocking_send_recv(), BlockingClient, client_socket_path() (+23 more)

### Community 12 - "Equatable"
Cohesion: 0.09
Nodes (43): Codable, Decoder, Double, Equatable, InsertRowView, Int, SubscribeStreamPayload, ChannelScope (+35 more)

### Community 13 - "Identifiable"
Cohesion: 0.06
Nodes (30): Identifiable, OptionSet, BridgeSpec, Int, Channel, Connection, HydraEvent, Kind (+22 more)

### Community 14 - "CodingKeys"
Cohesion: 0.04
Nodes (48): CodingKeys, aes67TX, appTapMakeupDB, backplaneDeviceName, backplaneInstalled, base, category, channelIndex (+40 more)

### Community 15 - "BroadcasterHandle"
Cohesion: 0.08
Nodes (24): Display, Formatter, BroadcasterBuilderError, Error, ServiceDnsPacketBuilderError, BroadcasterHandle, BroadcasterHandleDrop, BroadcasterHandleInner (+16 more)

### Community 16 - "Service"
Cohesion: 0.06
Nodes (28): DnsMessage, IntoName, IpAddr, Ord, Ordering, PartialOrd, ServiceBuilderError, Borrow (+20 more)

### Community 17 - "DeviceServer"
Cohesion: 0.11
Nodes (29): Fn, DeviceServer, Arc, Atomic, AtomicUsize, B, Box, BTreeMap (+21 more)

### Community 18 - "String"
Cohesion: 0.08
Nodes (18): PluginCategory, all, dynamics, eqFilter, favorites, instruments, masteringTools, modulation (+10 more)

### Community 19 - "flows_rx.rs"
Cohesion: 0.13
Nodes (31): AtomicI32, Poll, Channel, Command, FlowInfo, FlowsReceiver, FlowsReceiver<P>, FlowsReceiverInternal (+23 more)

### Community 20 - "channels_subscriber.rs"
Cohesion: 0.10
Nodes (31): ChannelOtherEnd, ChannelsSubscriber, ChannelsSubscriberInternal, ChannelSubscription, Command, Flow, FlowSource, MulticastFlow (+23 more)

### Community 21 - "Aes67Manager"
Cohesion: 0.09
Nodes (22): DispatchQueue, Int16, NWBrowser, NWParameters, streams, Aes67Manager, Aes67Rx, MulticastReceiver (+14 more)

### Community 22 - "VirtualInterfaceInfo"
Cohesion: 0.12
Nodes (13): ChannelLabelsPayload, VirtualInterfaceInfo, PatchScene, hydraSupportURL(), InterfaceStore, LabelStore, SceneStore, Bool (+5 more)

### Community 23 - "HiQnet"
Cohesion: 0.18
Nodes (11): Address, Array, Flags, Frame, HiQnet, Subscription, Int, UInt32 (+3 more)

### Community 24 - "ring_buffer.rs"
Cohesion: 0.18
Nodes (30): ExactSizeIterator, for_in_ring(), new_owned(), non_sequential_write_single_read(), ReadResult, FnMut, Item, test_close_items_until_after_reset() (+22 more)

### Community 25 - "HUI"
Cohesion: 0.10
Nodes (20): Int, Decoder, Event, fader, ping, scribble, switchState, HUI (+12 more)

### Community 26 - "Foundation"
Cohesion: 0.12
Nodes (7): AVFoundation, Foundation, HydraCore, HydraSurface, MetricKit, DaemonContext, Testing

### Community 27 - "View"
Cohesion: 0.11
Nodes (28): BridgeInfo, BridgeRole, ChannelFocus, ChannelScope, ConnMeters, DaemonClient, Font, GridSelection (+20 more)

### Community 28 - "GridView"
Cohesion: 0.15
Nodes (14): GroupDef, AxisItem, channel, group, AxisLayout, ChannelFocus, GridView, SignalMark (+6 more)

### Community 29 - "Value"
Cohesion: 0.08
Nodes (25): Int8, Binding, Bool, DispatchWorkItem, TimeInterval, Void, SyncedValue, Double (+17 more)

### Community 30 - "SurfaceBridge"
Cohesion: 0.15
Nodes (13): AnyObject, Never, MIDIBackend, Config, SlotKey, SurfaceBridge, Bool, Int (+5 more)

### Community 31 - "MultiIpIoError"
Cohesion: 0.11
Nodes (26): DnsRecordType, Discovery, discovery_packet(), DiscoveryBuilderError, DiscoveryHandle, DiscoveryHandleDrop, DiscoveryHandleInner, Drop (+18 more)

### Community 32 - "InstallerState"
Cohesion: 0.09
Nodes (18): ComponentCatalog, FooterView, Bool, DateFormatter, InstallerState, InstallerStep, complete, install (+10 more)

### Community 33 - "View"
Cohesion: 0.09
Nodes (14): AboutView, LocalizedStringKey, View, SurfaceConfigSheet, Int, Bool, Void, WelcomeSheet (+6 more)

### Community 34 - "DeviceInfo"
Cohesion: 0.11
Nodes (25): MacAddr, Channel, DeviceInfo, dummy_device_info(), five_ms_at_48000_hz(), large_values_no_overflow(), one_second_at_44100_hz(), one_second_at_48000_hz() (+17 more)

### Community 35 - "RouteManager"
Cohesion: 0.16
Nodes (12): BridgeManager, DeviceManager, DeviceOutputTap, MatrixStore, FlowInfo, RouteManager, Bool, PatchPoint (+4 more)

### Community 36 - "MatrixStore"
Cohesion: 0.16
Nodes (11): os_unfair_lock, Snapshot, EngineTap, MatrixStore, Bool, Connection, DispatchWorkItem, Int32 (+3 more)

### Community 37 - ".start"
Cohesion: 0.13
Nodes (10): BridgeInfo, BridgesPayload, ConfigPayload, DevicesPayload, FlowsPayload, PhysicalDeviceInfo, DaemonContext, DispatchSourceTimer (+2 more)

### Community 38 - "bytes.rs"
Cohesion: 0.10
Nodes (23): Arc, BroadcastReceiver, Mutex, Option, run_server(), align_wpos(), make_u16(), read_0term_str_from_buffer() (+15 more)

### Community 39 - "Result"
Cohesion: 0.14
Nodes (18): Copy, Iface, Socket, InterfacedMdnsSocket, InterfacedMdnsSocket<AsyncUdpSocket, Iface>, InterfacedMdnsSocket<Socket, Iface>, InterfacedMdnsSocket<UdpSocket, Iface>, MdnsSocket (+10 more)

### Community 40 - "InstallManager"
Cohesion: 0.12
Nodes (14): Pipe, Diagnostics, InstallManager, InstallResult, failure, success, Phase, failed (+6 more)

### Community 41 - "Aes67ParserExtraTests"
Cohesion: 0.14
Nodes (6): SDPParser, Data, Aes67ParserExtraTests, Data, Int, UInt8

### Community 42 - "ResponderMemoryEntry"
Cohesion: 0.10
Nodes (20): Cell, Hash, HashSet, DiscoveryEvent, Arc, Responder, ResponderMemory, ResponderMemoryEntry (+12 more)

### Community 43 - "SidebarView"
Cohesion: 0.13
Nodes (12): LocalizedStringKey, ModuleSourceInfo, NdiSourceInfo, PhysicalDeviceInfo, DeviceDetailView, InfoButton, SidebarView, Bool (+4 more)

### Community 44 - "NdiManager"
Cohesion: 0.15
Nodes (13): NdiManager, NdiRx, NdiTx, Bool, DispatchSourceTimer, Double, Float, Int (+5 more)

### Community 45 - "StripManager"
Cohesion: 0.15
Nodes (13): PluginPrefs, ScanCache, StripManager, Bool, Connection, Date, DispatchSourceTimer, Range (+5 more)

### Community 46 - "proto_arc.rs"
Cohesion: 0.08
Nodes (16): ChannelDescriptor, Descriptor2, deserialize_items(), deserialize_items_empty(), DestinationSocketDescriptor, Flags2, FlowDescriptorFooter, FlowDescriptorHeader (+8 more)

### Community 47 - "PluginHost"
Cohesion: 0.14
Nodes (15): Darwin, HydraPluginHostABI, ChainCommand, ChainManager, hlog(), PluginHost, PluginSpec, Data (+7 more)

### Community 48 - "SwiftUI"
Cohesion: 0.09
Nodes (16): AppLanguageStore, LanguagePicker, Badge, Bool, Color, Grid, gridAccent(), gridGray() (+8 more)

### Community 49 - "BridgeManager"
Cohesion: 0.16
Nodes (11): BridgeManager, Persisted, PresentBridge, AudioObjectID, Bool, DispatchWorkItem, Double, Int (+3 more)

### Community 50 - ".emit"
Cohesion: 0.14
Nodes (14): AVAudioFile, AVAudioPCMBuffer, EventCenter, HydraEvent, String, Void, Recording, RecordingManager (+6 more)

### Community 51 - "GridEntry"
Cohesion: 0.18
Nodes (11): Hashable, DeviceViewPatch, SignalDotPublic, Binding, Bool, CGFloat, Color, Int (+3 more)

### Community 52 - "Updater"
Cohesion: 0.14
Nodes (14): Release, Bool, Data, Error, TimeInterval, Timer, URL, UpdateError (+6 more)

### Community 53 - ".pairs"
Cohesion: 0.10
Nodes (13): destination, source, ChannelPairing, formatElapsed(), LoadSeverity, critical, elevated, normal (+5 more)

### Community 54 - "Component"
Cohesion: 0.12
Nodes (19): Component, Bool, Double, AppleScriptResult, InstallerEngine, Bool, Double, Void (+11 more)

### Community 55 - "ChannelRing"
Cohesion: 0.18
Nodes (13): ABLUtil, ChannelRing, Bool, Double, Float, Int, Int64, UnsafeMutablePointer (+5 more)

### Community 56 - "T"
Cohesion: 0.21
Nodes (17): ExternalBuffer, ExternalBufferParameters, ExternalRBInput, ExternalRBOutput, RBInput<T, P>, RBOutput, RingBufferShared, Arc (+9 more)

### Community 57 - ".new"
Cohesion: 0.23
Nodes (17): AtomicU16, FlowControlError, FlowsControlClient, minimal_device_info(), Arc, Box, ByteBuffer, Error (+9 more)

### Community 58 - "SettingsView.swift"
Cohesion: 0.11
Nodes (19): ChannelLabelsPayload, Date, PatchScene, AdvancedSettingsPane, AudioSettingsPane, ControlSettingsPane, GeneralSettingsPane, PluginRow (+11 more)

### Community 59 - "PolyphaseResampler"
Cohesion: 0.19
Nodes (6): PolyphaseResampler, ArraySlice, Double, Float, Int, PolyphaseResamplerTests

### Community 60 - "CoreMIDIBackend"
Cohesion: 0.14
Nodes (15): CoreMIDI, CustomStringConvertible, Error, MIDIEndpointRef, MIDIPacketList, check(), CoreMIDIBackend, MIDIError (+7 more)

### Community 61 - "DeviceManager"
Cohesion: 0.17
Nodes (13): DeviceIO, DeviceManager, Present, AudioDeviceIOProcID, AudioObjectID, Bool, Double, Float (+5 more)

### Community 62 - "PoolTxTap"
Cohesion: 0.15
Nodes (14): Aes67Tx, localIPv4Address(), Bool, DispatchSourceTimer, Double, Float, Int, NWConnection (+6 more)

### Community 63 - "SharedPluginHost"
Cohesion: 0.15
Nodes (10): ChainSpec, SharedPluginHost, Any, DispatchSourceTimer, Double, Process, TimeInterval, UInt64 (+2 more)

### Community 64 - "Ipv6Interface"
Cohesion: 0.17
Nodes (14): Addr, Ipv6Addr, Ipv6Interface, IpVersion, MulticastSocketEx, BTreeSet, Error, Ipv4Addr (+6 more)

### Community 65 - "GridView.swift"
Cohesion: 0.14
Nodes (17): Axis, GraphicsContext, NSClickGestureRecognizer, NSGestureRecognizerRepresentable, ObservableObject, CellField, HoverPos, HoverStateRef (+9 more)

### Community 66 - "ModuleRx"
Cohesion: 0.19
Nodes (15): CChar, HydraModule, moduleHostDeliver(), moduleHostLog(), moduleHostSourcesChanged(), ModuleRx, ModuleTx, Double (+7 more)

### Community 67 - "MetricsReporter"
Cohesion: 0.13
Nodes (16): Logger, MXDiagnosticPayload, MXMetricManagerSubscriber, MXMetricPayload, MetricsReporter, Data, URL, Category (+8 more)

### Community 68 - "run_server"
Cohesion: 0.13
Nodes (19): Arc, BroadcastReceiver, Mutex, Option, Receiver, Sender, run_server(), make_channel_change_notification() (+11 more)

### Community 69 - "DeviceOutputTap"
Cohesion: 0.17
Nodes (11): CATapDescription, DeviceOutputTap, AudioDeviceIOProcID, AudioObjectID, Bool, Double, Float, Int (+3 more)

### Community 70 - "InstallerWindowDelegate"
Cohesion: 0.14
Nodes (13): NSApplicationDelegate, NSObject, NSWindowDelegate, AppDelegate, HydraInstallerApp, InstallerWindowDelegate, Reason, close (+5 more)

### Community 71 - "ResampleServoTests"
Cohesion: 0.15
Nodes (5): ResampleServo, Bool, Double, Int, ResampleServoTests

### Community 72 - "DiscoveryBuilder"
Cohesion: 0.16
Nodes (9): DiscoveryBuilder, Default, DnsName, Duration, Option, Result, Self, TargetInterfaceV4 (+1 more)

### Community 73 - "ExternalBuffer<T>"
Cohesion: 0.11
Nodes (14): ExternalBuffer<Atomic<Sample>>, ExternalBuffer<T>, ExternalBufferParameters<T>, OwnedBuffer<Atomic<Sample>>, OwnedBuffer<T>, ProxyToBuffer, ProxyToSamplesBuffer, RingBufferShared<Sample, P> (+6 more)

### Community 74 - "Snapshot"
Cohesion: 0.18
Nodes (11): AudioBufferList, ContiguousArray, Conn, InMeter, NodeTx, Snapshot, Double, Float (+3 more)

### Community 75 - "run_server"
Cohesion: 0.23
Nodes (10): PeaksCallback, Multicaster, Multicaster<'s>, Arc, BroadcastReceiver, Option, Receiver, RwLock (+2 more)

### Community 76 - "Aes67Stream"
Cohesion: 0.25
Nodes (11): Aes67Device, Aes67Payload, Aes67Stream, Aes67TxInfo, Announcement, SAPParser, Bool, Double (+3 more)

### Community 77 - "ModuleManager"
Cohesion: 0.18
Nodes (6): ModuleInfo, ModulesPayload, ModuleManager, Bool, DispatchSourceTimer, Set

### Community 78 - "ChainTap"
Cohesion: 0.23
Nodes (9): ChainTap, EditorRef, StripRoute, Float, Int, Int32, UnsafeMutablePointer, UnsafeMutableRawPointer (+1 more)

### Community 79 - "HydraRT"
Cohesion: 0.17
Nodes (8): Accelerate, CoreAudio, HydraModuleABI, HydraNDIShim, HydraRT, HydraVST, Network, Synchronization

### Community 80 - "MenuBarPanel.swift"
Cohesion: 0.13
Nodes (12): Commands, ServiceManagement, UpdateCommands, AboutCommands, Font, MBSectionHeader, MBStatTile, MenuBarPanel (+4 more)

### Community 81 - "Cow"
Cohesion: 0.18
Nodes (7): Cow, Sized, IntoServiceTxt, &'static str, &'static [u8], &'static [u8; N], Vec<u8>

### Community 82 - "ChainHandle"
Cohesion: 0.26
Nodes (10): ChainHandle, Bool, Float, hydra_plugin_shm, Int, Int32, UInt32, UnsafeMutablePointer (+2 more)

### Community 83 - "RealTimeSamplesReceiver"
Cohesion: 0.25
Nodes (15): Channel, Command, get_min_max_end_timestamps(), PeriodicSamplesCollector, RealTimeSamplesReceiver, IntoIterator, Item, Option (+7 more)

### Community 84 - "DanteClockBrowser"
Cohesion: 0.16
Nodes (10): NetService, NetServiceBrowser, NetServiceBrowserDelegate, NetServiceDelegate, NSNumber, DanteClockBrowser, Bool, Data (+2 more)

### Community 85 - "log"
Cohesion: 0.27
Nodes (8): ObjectIdentifier, log(), Bool, NWConnection, NWListener, UInt16, Void, WebSocketServer

### Community 86 - "StateStorage"
Cohesion: 0.23
Nodes (13): Serialize, load_malformed_toml_fails(), load_missing_file_fails(), Box, Error, Result, Self, save_and_load_roundtrip() (+5 more)

### Community 87 - "Message"
Cohesion: 0.11
Nodes (18): Message, discoInfo, getAttributes, getNetworkInfo, getVDList, goodbye, hello, multiObjectParamSet (+10 more)

### Community 88 - "HiQnetServer"
Cohesion: 0.22
Nodes (8): HiQnetServer, MeterListener, Bool, NWConnection, NWListener, UInt16, UInt8, Void

### Community 89 - "String"
Cohesion: 0.21
Nodes (10): ChannelSettings, Arc, Channel, Self, Vec, SavedChannels, SavedChannelsSettings, get_chromecast_name() (+2 more)

### Community 90 - "media_clock.rs"
Cohesion: 0.18
Nodes (12): async_clock_receiver_to_realtime(), make_shared_media_clock(), media_clock_new_not_ready(), media_clock_update_overlay_becomes_ready(), media_clock_update_overlay_replaces(), Arc, ClockReceiver, PathBuf (+4 more)

### Community 91 - "UdpSocketWrapper"
Cohesion: 0.22
Nodes (11): create_mio_udp_socket(), create_tokio_udp_socket(), ReceiveBuffer, Ipv4Addr, Option, Receiver, Result, Self (+3 more)

### Community 92 - ".impl_run"
Cohesion: 0.21
Nodes (12): AsyncUdpSocket, Broadcaster, BroadcasterConfig, Arc, BTreeSet, Option, Receiver, Result (+4 more)

### Community 93 - "InfernoManager"
Cohesion: 0.20
Nodes (8): ConfigPayload, Int32, Process, InfernoManager, Bool, Int, String, URL

### Community 94 - "SurfaceManager"
Cohesion: 0.23
Nodes (3): SurfaceManager, DispatchSourceTimer, Void

### Community 95 - ".backplaneDeviceID"
Cohesion: 0.29
Nodes (6): BackplaneProbe, AudioObjectID, AudioObjectPropertyScope, Bool, Double, Int

### Community 96 - "AppKit"
Cohesion: 0.15
Nodes (7): AppKit, Carbon, Combine, CryptoKit, HydraDaemon, os, Notification.Name

### Community 97 - "AudioEngine"
Cohesion: 0.17
Nodes (11): AudioObjectPropertyListenerBlock, HydraSignpost, Aes67TxManager, Void, AudioEngine, EngineMetrics, AudioDeviceIOProcID, AudioObjectID (+3 more)

### Community 98 - "paginate_make_response"
Cohesion: 0.28
Nodes (15): InItem, Iterator, OutItem, extract_start_index(), ItemsInPacketIterator<'a, T>, paginate_make_response(), paginate_respond(), ByteBuffer (+7 more)

### Community 99 - "FlowChainCard"
Cohesion: 0.27
Nodes (5): FlowChainCard, Bool, Int, String, Void

### Community 100 - "ExternalBuffering"
Cohesion: 0.33
Nodes (10): ChannelsBuffering, ExternalBuffering, OwnedBuffering, Arc, Atomic, Clock, ClockDiff, Sample (+2 more)

### Community 101 - "MediaClock"
Cohesion: 0.25
Nodes (8): FineClock, MediaClock, Clock, Duration, LongClock, Option, timestamp_to_clock_value(), Timestamp

### Community 102 - "hydra_ndi.c"
Cohesion: 0.14
Nodes (4): hndi_source_t, hndi_find_sources(), hndi_load(), try_dlopen()

### Community 103 - "Headers/hydra_plugin_shm.h"
Cohesion: 0.18
Nodes (7): hydra_plugin_cmd, hydra_plugin_shm, hydra_plugin_shm_bytes(), hydra_plugin_shm_cmd(), hydra_plugin_shm_input(), hydra_plugin_shm_output(), hydra_plugin_shm_slot_floats()

### Community 104 - "ChannelsSubscriberInternal<P, B>"
Cohesion: 0.27
Nodes (4): ChannelsSubscriberInternal<P, B>, Flow<P>, IntoIterator, Item

### Community 105 - ".new_realtime"
Cohesion: 0.21
Nodes (9): Arc, Box, Future, Output, Pin, SamplesCallback, Self, Send (+1 more)

### Community 106 - "BroadcasterBuilder"
Cohesion: 0.22
Nodes (7): BroadcasterBuilder, BTreeSet, Default, Result, Self, TargetInterfaceV4, TargetInterfaceV6

### Community 107 - "Connection"
Cohesion: 0.26
Nodes (6): BinarySerde, Connection, make_packet(), RemoteInfo, Option, SocketAddr

### Community 108 - "Coordinator"
Cohesion: 0.21
Nodes (8): Binding, Context, Notification, NSSearchField, NSSearchFieldDelegate, Coordinator, SearchField, String

### Community 109 - "SidebarTab"
Cohesion: 0.14
Nodes (12): CaseIterable, Color, PluginPickerSheet, StripInfo, ViewMode, category, flat, vendor (+4 more)

### Community 110 - "CodingKeys"
Cohesion: 0.14
Nodes (14): CodingKey, CodingKeys, address, aes67On, channels, devices, flowIndex, interfaceID (+6 more)

### Community 111 - "AppDelegate"
Cohesion: 0.29
Nodes (5): AppDelegate, Bool, Notification, NSApplication, NSWindow

### Community 112 - "EnginePresence"
Cohesion: 0.19
Nodes (7): EnginePresence, noBackplane, offline, running, stopped, Bool, EnginePresenceTests

### Community 113 - "FlowEndpointKind"
Cohesion: 0.33
Nodes (6): FlowEndpointKind, app, bridge, device, deviceInput, deviceOutput

### Community 114 - "PositionReportDestination"
Cohesion: 0.18
Nodes (6): ExternalRBInput<T>, PositionReportDestination, RingBufferShared<T, P>, AtomicUsize, Self, Vec

### Community 115 - ".menuBarWave"
Cohesion: 0.23
Nodes (10): CGPoint, NSImage, Path, Shape, MenuBarStatusLabel, BrandMark, IconPack, CGFloat (+2 more)

### Community 116 - "WindowAccessor"
Cohesion: 0.22
Nodes (9): NSView, NSViewRepresentable, NSVisualEffectView, Context, NSWindow, Void, WindowAccessor, Context (+1 more)

### Community 117 - "DataType"
Cohesion: 0.15
Nodes (13): DataType, block, byte, float32, float64, long, long64, string (+5 more)

### Community 118 - "HydraApp/SidebarView.swift"
Cohesion: 0.23
Nodes (9): Aes67Stream, AppInfo, Content, AppCaptureDetailView, DetailHeader, detailMono(), detailRow(), InfoPopoverButton (+1 more)

### Community 119 - "include/hydra_plugin_shm.h"
Cohesion: 0.24
Nodes (7): hydra_plugin_cmd, hydra_plugin_shm, hydra_plugin_shm_bytes(), hydra_plugin_shm_cmd(), hydra_plugin_shm_input(), hydra_plugin_shm_output(), hydra_plugin_shm_slot_floats()

### Community 120 - "HiQnetDiscovery"
Cohesion: 0.30
Nodes (5): HiQnetDiscovery, DispatchSourceRead, Int32, UInt8, Void

### Community 121 - "wrapped_diff"
Cohesion: 0.21
Nodes (8): Clock, ClockDiff, wrapped_diff(), Channel<P>, PeriodicSamplesCollector<P>, RealTimeSamplesReceiver<P>, Clock, Sample

### Community 122 - "common.rs"
Cohesion: 0.09
Nodes (5): log_and_forget_err(), log_and_forget_ok(), LogAndForget, Result<T, E>, SamplesReader

### Community 123 - "Aes67Tests"
Cohesion: 0.23
Nodes (4): Aes67Tests, Bool, Data, UInt8

### Community 124 - "RealTimeBoxReceiver"
Cohesion: 0.33
Nodes (8): AtomicOptionBox, channel(), RealTimeBoxReceiver, RealTimeBoxSender, RealTimeBoxSender<T>, Arc, Box, Shared

### Community 125 - "CommandPalette"
Cohesion: 0.24
Nodes (7): Element, Array, CommandPalette, PaletteAction, Bool, Int, Void

### Community 126 - "ContentView"
Cohesion: 0.22
Nodes (5): NavigationSplitViewVisibility, ContentView, Binding, Bool, Color

### Community 127 - "DanteClockBrowser"
Cohesion: 0.18
Nodes (10): DanteClockBrowser, -initOBJC_DESIGNATED_INITIALIZER, -netServiceBrowserdidFindServicemoreComing, -netServiceBrowserdidRemoveServicemoreComing, -netServicedidNotResolve, -netServiceDidResolveAddress, -netServicedidUpdateTXTRecordData, NSNetServiceBrowserDelegate (+2 more)

### Community 128 - "DanteClockBrowser"
Cohesion: 0.18
Nodes (10): DanteClockBrowser, -initOBJC_DESIGNATED_INITIALIZER, -netServiceBrowserdidFindServicemoreComing, -netServiceBrowserdidRemoveServicemoreComing, -netServicedidNotResolve, -netServiceDidResolveAddress, -netServicedidUpdateTXTRecordData, NSNetServiceBrowserDelegate (+2 more)

### Community 129 - "build_and_install.sh"
Cohesion: 0.60
Nodes (9): build_driver(), customize_source(), fail(), fetch_source(), install_driver(), log(), require_xcode(), build_and_install.sh script (+1 more)

### Community 130 - "release.sh"
Cohesion: 0.29
Nodes (5): fail(), header(), note(), run(), release.sh script

### Community 131 - ".shutdown"
Cohesion: 0.22
Nodes (3): DaemonContext, DaemonRuntime, Bool

### Community 132 - "hydra-plugin-host.build/DerivedSources/GeneratedAssetSymbols.swift"
Cohesion: 0.22
Nodes (7): DeveloperToolsSupport, DeveloperToolsSupport.ColorResource, DeveloperToolsSupport.ImageResource, ResourceBundleClass, DeveloperToolsSupport.ColorResource, DeveloperToolsSupport.ImageResource, ResourceBundleClass

### Community 133 - "install_local.sh"
Cohesion: 0.58
Nodes (8): device_visible(), do_install(), do_status(), do_uninstall(), fail(), log(), restart_coreaudiod(), install_local.sh script

### Community 134 - "GFAD"
Cohesion: 0.22
Nodes (9): GFAD, enable, faderMode, faderUByteValue, faderValue, glowColour, glowFunction, motorUByteValue (+1 more)

### Community 135 - "SubObject"
Cohesion: 0.22
Nodes (8): SubObject, fader, lcd, onSw, selSw, soloSw, Bool, Int

### Community 136 - "DaemonService"
Cohesion: 0.25
Nodes (4): App, DaemonService, HydraApp, Scene

### Community 137 - "generate_xcodeproj.rb"
Cohesion: 0.36
Nodes (4): c_framework(), common!(), each_config(), sync_dir()

### Community 138 - "StripGridView.swift"
Cohesion: 0.36
Nodes (7): linearToDb(), MeterColumn, StripCardView, StripGridView, StripMeters, Color, Float

### Community 139 - "TLSW"
Cohesion: 0.25
Nodes (8): TLSW, ledOutputColour, offColour, onColour, pressedValue, releasedValue, switchMode, switchStatus

### Community 140 - "BridgeRole"
Cohesion: 0.38
Nodes (5): BridgeRole, both, input, output, SetBridgeRolePayload

### Community 141 - "ShakeEffect"
Cohesion: 0.33
Nodes (5): CGFloat, CGSize, GeometryEffect, ProjectionTransform, ShakeEffect

### Community 142 - "bridges_install.sh"
Cohesion: 0.53
Nodes (5): ALL, fail(), log(), selected(), bridges_install.sh script

### Community 143 - "peaks_of_buffers"
Cohesion: 0.40
Nodes (5): peaks_of_buffers(), Arc, P, Sample, Vec

### Community 146 - "build_installer.sh"
Cohesion: 0.70
Nodes (4): build_installer_for_arch(), fail(), log(), build_installer.sh script

### Community 147 - "render"
Cohesion: 0.60
Nodes (4): _lerp(), main(), Render the Hydra mark at resolution S×S (RGBA, transparent corners)., render()

### Community 148 - "NetworkUtils.swift"
Cohesion: 0.40
Nodes (4): NetworkUtils, Set, String, SystemConfiguration

### Community 149 - "CHLCD"
Cohesion: 0.40
Nodes (5): CHLCD, channelName, ledColourOutput, mode, text

### Community 150 - "RecordingInfo"
Cohesion: 0.47
Nodes (3): RecordingInfo, RecordingsPayload, Date

### Community 151 - "build_pkg.sh"
Cohesion: 0.83
Nodes (3): fail(), log(), build_pkg.sh script

### Community 152 - "EditorTarget"
Cohesion: 0.50
Nodes (4): EditorTarget, local, none, remote

### Community 153 - "SlotsCtl"
Cohesion: 0.50
Nodes (4): SlotsCtl, currentSlotSel, refreshCurrentSel, slotAssignments

### Community 156 - ".new"
Cohesion: 0.50
Nodes (3): common_channels_descriptor_new_matches_device_info(), CommonChannelsDescriptor, Self

### Community 157 - "set_current_thread_realtime"
Cohesion: 0.50
Nodes (3): Error, Result, set_current_thread_realtime()

### Community 158 - "GHAsset"
Cohesion: 1.00
Nodes (3): Decodable, GHAsset, GHRelease

## Knowledge Gaps
- **404 isolated node(s):** `Script-5523C934D0F4E104405D721B.sh script`, `Script-C641665DE93AF2886FB53446.sh script`, `ResourceBundleClass`, `DeveloperToolsSupport.ColorResource`, `DeveloperToolsSupport.ImageResource` (+399 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **45 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `String` to `Ipv6Interface`, `DeviceInfo`, `MetricsReporter`, `FlowsTransmitter`, `TransmitMulticasts`, `SubObject`, `Identifiable`, `CodingKeys`, `Service`, `Cow`, `channels_subscriber.rs`, `StateStorage`?**
  _High betweenness centrality (0.365) - this node is a cross-community bridge._
- **Why does `DeviceInfo` connect `DeviceInfo` to `FlowsTransmitter`, `run_server`, `TransmitMulticasts`, `bytes.rs`, `.new_realtime`, `run_server`, `DeviceServer`, `flows_rx.rs`, `channels_subscriber.rs`, `StateStorage`, `String`, `.new`, `.new`?**
  _High betweenness centrality (0.164) - this node is a cross-community bridge._
- **Why does `NodeKind` connect `Identifiable` to `String`, `Equatable`, `SidebarTab`, `Sendable`?**
  _High betweenness centrality (0.118) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `DaemonClient` (e.g. with `Aes67Payload` and `ChannelLabelsPayload`) actually correct?**
  _`DaemonClient` has 6 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Script-5523C934D0F4E104405D721B.sh script`, `Script-C641665DE93AF2886FB53446.sh script`, `ResourceBundleClass` to the rest of the system?**
  _404 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Hydra.c` be split into smaller, more focused modules?**
  _Cohesion score 0.08622620380739082 - nodes in this community are weakly interconnected._
- **Should `WSMessage` be split into smaller, more focused modules?**
  _Cohesion score 0.02664576802507837 - nodes in this community are weakly interconnected._