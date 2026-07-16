import SwiftUI

struct SelectionView: View {
    @EnvironmentObject var state: InstallerState

    private var groupedComponents: [(String, [Component])] {
        let grouped = Dictionary(grouping: ComponentCatalog.components, by: { $0.category })
        return grouped
            .map { ($0.key, $0.value.sorted { $0.displayName < $1.displayName }) }
            .sorted { a, b in
                // Core first, then Bridges
                if a.0.contains("Core") && !b.0.contains("Core") { return true }
                if !a.0.contains("Core") && b.0.contains("Core") { return false }
                return a.0 < b.0
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Select virtual audio devices")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Core components are required. Choose which loopback bridges to create.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button("Select All") { state.selectAll() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("Deselect All") { state.deselectAll() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedComponents, id: \.0) { category, comps in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(category.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Rectangle()
                                    .fill(Color(NSColor.separatorColor))
                                    .frame(height: 1)
                            }

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 8) {
                                ForEach(comps) { comp in
                                    ComponentCheckRow(component: comp)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ComponentCheckRow: View {
    @EnvironmentObject var state: InstallerState
    let component: Component

    private var isSelected: Bool {
        state.selectedComponentIDs.contains(component.id)
    }

    private var isAlreadyInstalled: Bool {
        state.detectedExistingComponents.contains(component)
    }

    private var isRequired: Bool {
        component.isRequired
    }

    var body: some View {
        Button(action: {
            if !isRequired {
                state.toggle(component.id)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: isRequired ? "lock.square.fill" : (isSelected ? "checkmark.square.fill" : "square"))
                    .font(.system(size: 16))
                    .foregroundColor(isRequired ? .secondary : (isSelected ? .accentColor : .secondary))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(component.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isRequired ? .secondary : .primary)
                        
                        if isAlreadyInstalled {
                            Text("INSTALLED")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule().fill(Color.green.opacity(0.18))
                                )
                                .foregroundColor(.green)
                        }
                    }
                    Text(component.description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isRequired)
    }
}
