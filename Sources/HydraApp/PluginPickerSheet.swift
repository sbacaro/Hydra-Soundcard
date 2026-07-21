import SwiftUI
import HydraCore

struct PluginPickerSheet: View {
    enum ViewMode: String, CaseIterable, Identifiable {
        case flat = "List"
        case category = "By Category"
        case vendor = "By Vendor"
        var id: String { rawValue }
    }

    @Environment(DaemonClient.self) private var client
    let strip: StripInfo
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: String = PluginCategory.all.rawValue
    @State private var selectedVendor: String = "All"
    @State private var showOnlyFavorites = false
    @State private var viewMode: ViewMode = .flat

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                BrandMark(size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add Insert")
                        .font(.system(size: 16, weight: .bold))
                    Text("to \(strip.key)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            Divider()
            
            VStack(spacing: 10) {
                // Search bar & Filters row
                HStack(spacing: 8) {
                    SearchField(text: $searchText, prompt: "Search plug-ins (e.g. comp, eq, FabFilter)")

                    Picker("", selection: $selectedVendor) {
                        Text("All Makers").tag("All")
                        ForEach(availableVendors, id: \.self) { vendor in
                            Text(vendor).tag(vendor)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)

                    Picker("", selection: $viewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                
                // Horizontal category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Button(action: {
                                selectedCategory = cat
                            }) {
                                HStack(spacing: 4) {
                                    if cat == PluginCategory.favorites.rawValue {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 9))
                                    }
                                    Text(cat)
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedCategory == cat ? Theme.accent : Color(.controlBackgroundColor))
                                .foregroundStyle(selectedCategory == cat ? .white : .primary)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(12)
            Divider()
            
            // Plugin content view
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if filteredPlugins.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                                .foregroundStyle(.tertiary)
                            Text("No plug-ins found")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("Try refining your search terms or clearing category & maker filters.")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        switch viewMode {
                        case .flat:
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(filteredPlugins) { plugin in
                                    pluginRow(plugin)
                                }
                            }
                        case .category:
                            let groups = PluginSearchEngine.groupByCategory(plugins: filteredPlugins)
                            ForEach(groups, id: \.category) { group in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(group.category.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                        .padding(.leading, 4)
                                        .padding(.top, 4)
                                    
                                    ForEach(group.plugins) { plugin in
                                        pluginRow(plugin)
                                    }
                                }
                            }
                        case .vendor:
                            let groups = PluginSearchEngine.groupByVendor(plugins: filteredPlugins)
                            ForEach(groups, id: \.vendor) { group in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(group.vendor.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                        .padding(.leading, 4)
                                        .padding(.top, 4)
                                    
                                    ForEach(group.plugins) { plugin in
                                        pluginRow(plugin)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(12)
            }
            
            if client.vst.scanning {
                Divider()
                HStack(spacing: 8) {
                    ProgressView(value: client.vst.scanProgress)
                        .tint(Theme.accent)
                    Text(client.vst.scanLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }
        }
        .frame(minWidth: 480, minHeight: 560)
    }
    
    private var availableCategories: [String] {
        PluginSearchEngine.extractCategories(from: client.vst.pickerPlugins())
    }

    private var availableVendors: [String] {
        PluginSearchEngine.extractVendors(from: client.vst.pickerPlugins())
    }
    
    private var filteredPlugins: [VSTPlugin] {
        PluginSearchEngine.filter(
            plugins: client.vst.pickerPlugins(),
            query: searchText,
            categoryFilter: selectedCategory,
            vendorFilter: selectedVendor,
            showFavoritesOnly: showOnlyFavorites,
            favoriteIDs: Set(client.vst.favoriteIDs)
        )
    }
    
    private func pluginRow(_ plugin: VSTPlugin) -> some View {
        let isFavorite = client.vst.favoriteIDs.contains(plugin.id)
        
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(plugin.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    if plugin.offline {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.warning)
                    }
                }
                
                HStack(spacing: 6) {
                    Text(plugin.displayVendor)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)

                    Text(plugin.displayCategory)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.12))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Button(action: {
                client.setPluginFavorite(id: plugin.id, favorite: !isFavorite)
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(isFavorite ? Theme.accent : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            var updated = strip
            updated.inserts.append(plugin)
            let newIndex = updated.inserts.count - 1
            client.setStrip(updated)
            client.openPluginEditor(stripID: strip.id, index: newIndex)
            dismiss()
        }
    }
}

