// Hydra Audio — GPL-3.0
// Plugin-management model tests (Settings → Plugins feature): availability/favorite
// filtering, VST3 type classification, backward-compatible decode, and message
// round-trips. Pure logic — runs in CI without Core Audio or a host.

import Testing
import Foundation
@testable import HydraCore

struct PluginManagementTests {

    // MARK: pickerPlugins() — what the strip's insert picker offers.

    @Test func pickerHidesDisabledAndPutsFavoritesFirst() {
        let zebra = VSTPlugin(id: "a", name: "Zebra", vendor: "V")
        let apple = VSTPlugin(id: "b", name: "Apple", vendor: "V")
        let mango = VSTPlugin(id: "c", name: "Mango", vendor: "V")
        let payload = VSTPayload(available: [zebra, apple, mango],
                                 disabledIDs: ["c"],          // Mango hidden
                                 favoriteIDs: ["a"])          // Zebra starred
        // Mango filtered out; Zebra (favorite) first, then Apple alphabetically.
        #expect(payload.pickerPlugins().map(\.id) == ["a", "b"])
    }

    @Test func pickerDefaultShowsEverythingAlphabetical() {
        let p = VSTPayload(available: [
            VSTPlugin(id: "1", name: "Beta",  vendor: "V"),
            VSTPlugin(id: "2", name: "alpha", vendor: "V"),   // case-insensitive sort
        ])
        #expect(p.pickerPlugins().map(\.name) == ["alpha", "Beta"])
    }

    @Test func pickerExcludesOfflinePlugins() {
        let ok  = VSTPlugin(id: "ok",  name: "Good",   vendor: "V")
        let bad = VSTPlugin(id: "bad", name: "Crashy", vendor: "V", offline: true)
        let p = VSTPayload(available: [ok, bad])
        // An offline (hung/crashed) plugin is shown in the manager but never
        // offered as an insert.
        #expect(p.pickerPlugins().map(\.id) == ["ok"])
    }

    // MARK: Type classification from the VST3 subcategory string.

    @Test func instrumentDetection() {
        #expect(VSTPlugin(id: "i", name: "Synth", vendor: "V",
                          category: "Instrument|Synth").isInstrument)
        #expect(!VSTPlugin(id: "e", name: "EQ", vendor: "V",
                           category: "Fx|EQ").isInstrument)
    }

    @Test func primaryType() {
        #expect(VSTPlugin(id: "1", name: "R", vendor: "V", category: "Fx|Reverb").primaryType == "Fx")
        #expect(VSTPlugin(id: "2", name: "S", vendor: "V", category: "Instrument").primaryType == "Instrument")
        // Empty category (legacy data) falls back to the historical "Fx".
        #expect(VSTPlugin(id: "3", name: "L", vendor: "V").primaryType == "Fx")
    }

    // MARK: Backward compatibility — old persisted plugins have no `category`.

    @Test func decodeLegacyPluginWithoutCategory() throws {
        let json = Data(#"{"id":"a#0","name":"Comp","vendor":"Acme"}"#.utf8)
        let p = try JSONDecoder().decode(VSTPlugin.self, from: json)
        #expect(p.category == "")
        #expect(!p.isInstrument)
    }

    @Test func decodeLegacyPayloadWithoutNewFields() throws {
        // A pre-feature VSTPayload (no disabledIDs/favoriteIDs) must still decode.
        let json = Data(#"{"available":[],"scanning":false,"scanProgress":0,"scanLabel":""}"#.utf8)
        let payload = try JSONDecoder().decode(VSTPayload.self, from: json)
        #expect(payload.disabledIDs == [])
        #expect(payload.favoriteIDs == [])
    }

    // MARK: Message round-trips (app → daemon).

    @Test func setPluginAvailableRoundTrips() throws {
        let msg = WSMessage.setPluginAvailable(.init(id: "bundle#2", available: false))
        let decoded = try JSONDecoder().decode(WSMessage.self, from: JSONEncoder().encode(msg))
        guard case let .setPluginAvailable(p) = decoded else {
            Issue.record("decoded to wrong case: \(decoded)"); return
        }
        #expect(p == PluginAvailabilityPayload(id: "bundle#2", available: false))
    }

    @Test func setPluginFavoriteRoundTrips() throws {
        let msg = WSMessage.setPluginFavorite(.init(id: "bundle#2", favorite: true))
        let decoded = try JSONDecoder().decode(WSMessage.self, from: JSONEncoder().encode(msg))
        guard case let .setPluginFavorite(p) = decoded else {
            Issue.record("decoded to wrong case: \(decoded)"); return
        }
        #expect(p == PluginFavoritePayload(id: "bundle#2", favorite: true))
    }

    // MARK: Strip side (transmitter / receiver inserts).

    @Test func stripDefaultsToSourceSide() {
        let strip = StripInfo(nodeID: "bp", channelIndex: 4, stereo: false)
        #expect(strip.side == .source)
    }

    @Test func decodeLegacyStripWithoutSideIsSource() throws {
        // A strip persisted before the `side` field must decode as the source
        // (transmitter) side — its historical, only behaviour.
        let json = Data(#"""
        {"id":"00000000-0000-0000-0000-000000000001","nodeID":"bp",
         "channelIndex":2,"stereo":false,"trim":1.0,"inserts":[]}
        """#.utf8)
        let strip = try JSONDecoder().decode(StripInfo.self, from: json)
        #expect(strip.side == .source)
        #expect(strip.isolated)            // also defaulted
    }

    @Test func sideRoundTripsAndKeysDiffer() throws {
        // A source and a destination strip can sit on the SAME channel: their
        // keys must differ so both persist and resolve independently.
        let tx = StripInfo(nodeID: "bp", channelIndex: 6, stereo: false, side: .source)
        let rx = StripInfo(nodeID: "bp", channelIndex: 6, stereo: false, side: .destination)
        #expect(tx.key != rx.key)
        #expect(tx.key == "bp:6")          // unchanged historical form
        #expect(rx.key == "bp:6:rx")

        let decoded = try JSONDecoder().decode(StripInfo.self,
                                               from: JSONEncoder().encode(rx))
        #expect(decoded.side == .destination)
        #expect(decoded.key == "bp:6:rx")
    }

    // MARK: PluginSearchEngine tests

    @Test func searchRelevanceRanking() {
        let proQ3 = VSTPlugin(id: "1", name: "Pro-Q 3", vendor: "FabFilter", category: "Fx|EQ")
        let proC2 = VSTPlugin(id: "2", name: "Pro-C 2", vendor: "FabFilter", category: "Fx|Dynamics")
        let qEq   = VSTPlugin(id: "3", name: "Channel EQ", vendor: "Apple", category: "Fx|EQ")

        let plugins = [qEq, proC2, proQ3]

        // Search "Pro-Q" should rank "Pro-Q 3" highest (prefix match)
        let resProQ = PluginSearchEngine.filter(plugins: plugins, query: "Pro-Q")
        #expect(resProQ.first?.id == "1")

        // Search "FabFilter" should match both FabFilter plugins
        let resFab = PluginSearchEngine.filter(plugins: plugins, query: "FabFilter")
        #expect(resFab.count == 2)
    }

    @Test func audioTermAliasMatching() {
        let comp = VSTPlugin(id: "1", name: "CL 1B", vendor: "Tube-Tech", category: "Fx|Dynamics")
        let verb = VSTPlugin(id: "2", name: "Valhalla VintageVerb", vendor: "Valhalla", category: "Fx|Reverb")
        let synth = VSTPlugin(id: "3", name: "Serum", vendor: "Xfer", category: "Instrument|Synth")

        let plugins = [comp, verb, synth]

        // Alias "compressor" should match "Fx|Dynamics"
        let resComp = PluginSearchEngine.filter(plugins: plugins, query: "compressor")
        #expect(resComp.map(\.id) == ["1"])

        // Alias "reverb" should match "Fx|Reverb"
        let resVerb = PluginSearchEngine.filter(plugins: plugins, query: "reverb")
        #expect(resVerb.map(\.id) == ["2"])

        // Alias "synth" should match "Instrument|Synth"
        let resSynth = PluginSearchEngine.filter(plugins: plugins, query: "synth")
        #expect(resSynth.map(\.id) == ["3"])
    }

    @Test func categoryAndVendorExtractionAndGrouping() {
        let p1 = VSTPlugin(id: "1", name: "Pro-Q 3", vendor: "FabFilter", category: "Fx|EQ")
        let p2 = VSTPlugin(id: "2", name: "Saturn 2", vendor: "FabFilter", category: "Fx|Distortion")
        let p3 = VSTPlugin(id: "3", name: "L2", vendor: "Waves", category: "Fx|Dynamics")

        let plugins = [p1, p2, p3]

        let vendors = PluginSearchEngine.extractVendors(from: plugins)
        #expect(vendors == ["FabFilter", "Waves"])

        let vendorGroups = PluginSearchEngine.groupByVendor(plugins: plugins)
        #expect(vendorGroups.count == 2)

        let categoryGroups = PluginSearchEngine.groupByCategory(plugins: plugins)
        #expect(categoryGroups.count >= 2)
    }
}

