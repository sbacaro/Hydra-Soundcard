// Hydra Audio — GPL-3.0
// Intelligent search, relevance ranking, category classification, and vendor grouping
// for VST3 plugins across Hydra.

import Foundation

/// High-level standardized audio plugin categories.
public enum PluginCategory: String, CaseIterable, Sendable, Codable {
    case all = "All"
    case favorites = "Favorites"
    case dynamics = "Dynamics"
    case eqFilter = "EQ & Filter"
    case reverbDelay = "Reverb & Delay"
    case modulation = "Modulation"
    case pitchDistortion = "Pitch & Saturation"
    case masteringTools = "Mastering & Tools"
    case instruments = "Instruments"
    case other = "Other"

    /// Matches a VSTPlugin's raw VST3 subcategory string to a high-level `PluginCategory`.
    public static func classify(_ categoryString: String) -> PluginCategory {
        let raw = categoryString.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        if raw.contains("instrument") || raw.contains("synth") || raw.contains("sampler") || raw.contains("drum") {
            return .instruments
        }
        if raw.contains("dynamic") || raw.contains("comp") || raw.contains("limiter") || raw.contains("gate") || raw.contains("expander") {
            return .dynamics
        }
        if raw.contains("eq") || raw.contains("equalizer") || raw.contains("filter") {
            return .eqFilter
        }
        if raw.contains("reverb") || raw.contains("delay") || raw.contains("echo") {
            return .reverbDelay
        }
        if raw.contains("modulat") || raw.contains("chorus") || raw.contains("flanger") || raw.contains("phaser") || raw.contains("tremolo") {
            return .modulation
        }
        if raw.contains("pitch") || raw.contains("distort") || raw.contains("saturat") || raw.contains("amp") {
            return .pitchDistortion
        }
        if raw.contains("master") || raw.contains("restorat") || raw.contains("analyzer") || raw.contains("tool") {
            return .masteringTools
        }
        return .other
    }
}

public extension VSTPlugin {
    /// Human-readable vendor name ("Unknown" if empty or whitespace-only).
    var displayVendor: String {
        let trimmed = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unknown" : trimmed
    }

    /// High-level audio category derived from VST3 class info.
    var mainCategory: PluginCategory {
        PluginCategory.classify(category)
    }

    /// Primary display category string (e.g. "Dynamics", "EQ & Filter", "Instruments", or raw subcategory).
    var displayCategory: String {
        if category.isEmpty {
            return isInstrument ? PluginCategory.instruments.rawValue : "Fx"
        }
        let cat = mainCategory
        return cat == .other ? category : cat.rawValue
    }
}

/// Unified search and filter engine for VST plugins.
public struct PluginSearchEngine: Sendable {
    
    /// Audio term aliases mapping query tokens to category names or audio concepts.
    private static let audioAliases: [String: [String]] = [
        "compressor": ["dynamics", "comp", "limiter", "gate", "expander", "fx|dynamics"],
        "comp": ["dynamics", "fx|dynamics"],
        "limiter": ["dynamics", "mastering"],
        "eq": ["equalizer", "filter", "fx|eq"],
        "equalizer": ["eq", "filter"],
        "verb": ["reverb", "delay", "echo", "space", "fx|reverb"],
        "reverb": ["verb", "delay", "echo", "space"],
        "delay": ["echo", "reverb"],
        "synth": ["instrument", "instrument|synth", "keyboard", "sampler"],
        "vsti": ["instrument"],
        "piano": ["instrument", "sampler"],
        "drum": ["instrument", "sampler"],
        "distortion": ["pitch", "saturation", "amp"],
        "sat": ["saturation", "distortion"],
        "master": ["mastering", "limiter", "analyzer"]
    ]

    /// Calculate a relevance score for a given plugin against a search query.
    /// Returns 0 if the plugin does not match the search query at all.
    public static func relevanceScore(for plugin: VSTPlugin, query: String) -> Int {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 1 } // All plugins match an empty query equally

        let qFolded = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let nameFolded = plugin.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let vendorFolded = plugin.displayVendor.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let categoryFolded = plugin.category.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let mainCatFolded = plugin.mainCategory.rawValue.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        var score = 0

        // 1. Exact match on name
        if nameFolded == qFolded {
            score += 1000
        }
        // 2. Name starts with query
        else if nameFolded.hasPrefix(qFolded) {
            score += 800
        }
        // 3. Word boundary in name starts with query (e.g. "Pro-Q" matched by "Q")
        else if nameFolded.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains(where: { $0.hasPrefix(qFolded) }) {
            score += 700
        }
        // 4. Name contains query substring
        else if nameFolded.contains(qFolded) {
            score += 500
        }

        // 5. Vendor match
        if vendorFolded == qFolded {
            score += 400
        } else if vendorFolded.contains(qFolded) {
            score += 300
        }

        // 6. Category match
        if mainCatFolded.contains(qFolded) || categoryFolded.contains(qFolded) {
            score += 250
        }

        // 7. Audio term alias matching
        let tokens = qFolded.split(whereSeparator: \.isWhitespace).map(String.init)
        for token in tokens {
            if let aliases = audioAliases[token] {
                for alias in aliases {
                    if nameFolded.contains(alias) || categoryFolded.contains(alias) || mainCatFolded.contains(alias) {
                        score += 200
                        break
                    }
                }
            }
        }

        // 8. Fallback fuzzy match across combined metadata string
        if score == 0 {
            let haystack = "\(plugin.name) \(plugin.displayVendor) \(plugin.category) \(plugin.mainCategory.rawValue)"
            if haystack.fuzzyMatches(trimmed) {
                score += 100
            }
        }

        return score
    }

    /// Filter and rank plugins based on search query, category, vendor, and favorites.
    public static func filter(
        plugins: [VSTPlugin],
        query: String = "",
        categoryFilter: String = "",
        vendorFilter: String = "",
        showFavoritesOnly: Bool = false,
        favoriteIDs: Set<String> = []
    ) -> [VSTPlugin] {
        plugins.compactMap { plugin -> (plugin: VSTPlugin, score: Int, isFav: Bool)? in
            // Filter by favorites
            let isFav = favoriteIDs.contains(plugin.id)
            if showFavoritesOnly && !isFav {
                return nil
            }

            // Filter by vendor
            if !vendorFilter.isEmpty && vendorFilter != "All" {
                if plugin.displayVendor.caseInsensitiveCompare(vendorFilter) != .orderedSame {
                    return nil
                }
            }

            // Filter by category
            if !categoryFilter.isEmpty && categoryFilter != "All" {
                if categoryFilter == PluginCategory.favorites.rawValue {
                    if !isFav { return nil }
                } else if categoryFilter == PluginCategory.instruments.rawValue {
                    if !plugin.isInstrument && plugin.mainCategory != .instruments { return nil }
                } else if let catEnum = PluginCategory(rawValue: categoryFilter) {
                    if plugin.mainCategory != catEnum { return nil }
                } else {
                    // Fallback comparison against primaryType or category string
                    let matchPrimary = plugin.primaryType.caseInsensitiveCompare(categoryFilter) == .orderedSame
                    let matchCategory = plugin.category.localizedCaseInsensitiveContains(categoryFilter)
                    if !matchPrimary && !matchCategory { return nil }
                }
            }

            // Search query relevance score
            let score = relevanceScore(for: plugin, query: query)
            guard score > 0 else { return nil }

            return (plugin, score, isFav)
        }
        .sorted { a, b in
            // Primary sort by relevance score if query is present
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if a.score != b.score {
                    return a.score > b.score
                }
            }
            // Secondary sort: favorites first
            if a.isFav != b.isFav {
                return a.isFav
            }
            // Tertiary sort: alphabetical by name
            return a.plugin.name.localizedCaseInsensitiveCompare(b.plugin.name) == .orderedAscending
        }
        .map(\.plugin)
    }

    /// Extract unique sorted vendor names from a list of plugins.
    public static func extractVendors(from plugins: [VSTPlugin]) -> [String] {
        let vendors = Set(plugins.map(\.displayVendor))
        return vendors.sorted()
    }

    /// Extract available category display strings from a list of plugins.
    public static func extractCategories(from plugins: [VSTPlugin]) -> [String] {
        var categories: [String] = [PluginCategory.all.rawValue, PluginCategory.favorites.rawValue]

        let mainCats = Set(plugins.map(\.mainCategory.rawValue))
        let sortedMain = PluginCategory.allCases
            .map(\.rawValue)
            .filter { mainCats.contains($0) && $0 != PluginCategory.all.rawValue && $0 != PluginCategory.favorites.rawValue }

        categories.append(contentsOf: sortedMain)
        return categories
    }

    /// Group plugins by Category for sectioned list display.
    public static func groupByCategory(plugins: [VSTPlugin]) -> [(category: String, plugins: [VSTPlugin])] {
        let dict = Dictionary(grouping: plugins, by: \.displayCategory)
        return dict.keys.sorted().map { cat in
            (category: cat, plugins: dict[cat] ?? [])
        }
    }

    /// Group plugins by Vendor for sectioned list display.
    public static func groupByVendor(plugins: [VSTPlugin]) -> [(vendor: String, plugins: [VSTPlugin])] {
        let dict = Dictionary(grouping: plugins, by: \.displayVendor)
        return dict.keys.sorted().map { v in
            (vendor: v, plugins: dict[v] ?? [])
        }
    }
}

// MARK: - Fuzzy matching

public extension StringProtocol {
    /// Case- and diacritic-insensitive fuzzy match. The query is split into
    /// whitespace tokens; each token must appear as an in-order subsequence of the
    /// receiver, but tokens may match in ANY order and anywhere.
    func fuzzyMatches(_ query: String) -> Bool {
        func fold(_ s: String) -> [Character] {
            Array(s.folding(options: [.caseInsensitive, .diacriticInsensitive],
                            locale: .current))
        }
        let tokens = query.split(whereSeparator: \.isWhitespace).map { fold(String($0)) }
        guard !tokens.isEmpty else { return true }
        let hay = fold(String(self)).filter { !$0.isWhitespace }
        for needle in tokens where !needle.isEmpty {
            var n = 0
            for ch in hay where ch == needle[n] {
                n += 1
                if n == needle.count { break }
            }
            if n != needle.count { return false }
        }
        return true
    }
}

