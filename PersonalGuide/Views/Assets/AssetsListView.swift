// MARK: - AssetsListView.swift
// PersonalGuide
//
// Registry of user's physical and digital assets (devices, vehicles, home, appliances).

import SwiftUI
import SwiftData

struct AssetsListView: View {

    @Query(sort: \Asset.updatedAt, order: .reverse)
    private var allAssets: [Asset]

    @State private var selectedFilter: AssetType?
    @State private var showCreateAsset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PGSpacing.lg) {

                    // MARK: - Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PGSpacing.xs) {
                            FilterPill(title: "All (\(allAssets.count))", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }

                            ForEach(AssetType.allCases) { type in
                                let count = allAssets.filter { $0.assetType == type }.count
                                if count > 0 || selectedFilter == type {
                                    FilterPill(title: "\(type.displayName) (\(count))", isSelected: selectedFilter == type) {
                                        selectedFilter = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, PGSpacing.md)
                    }

                    // MARK: - Asset List
                    if filteredAssets.isEmpty {
                        PGEmptyState(
                            icon: "cube.box",
                            title: "No assets added",
                            message: "Add your car, phone, laptop, or appliances to track warranties, insurance, and service cases in one place.",
                            actionTitle: "Add your first asset",
                            action: { showCreateAsset = true }
                        )
                        .padding(.horizontal, PGSpacing.md)
                    } else {
                        VStack(spacing: PGSpacing.sm) {
                            ForEach(filteredAssets) { asset in
                                NavigationLink(destination: AssetDetailView(asset: asset)) {
                                    AssetCard(asset: asset)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, PGSpacing.md)
                    }
                }
                .padding(.vertical, PGSpacing.md)
                .padding(.bottom, PGSpacing.xxl)
            }
            .background(Color.pgBackground)
            .navigationTitle("Assets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateAsset = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.pgPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreateAsset) {
                CreateAssetView()
            }
        }
    }

    private var filteredAssets: [Asset] {
        if let selectedFilter {
            return allAssets.filter { $0.assetType == selectedFilter }
        }
        return allAssets
    }
}

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pgCaption)
                .foregroundStyle(isSelected ? .white : .pgTextPrimary)
                .padding(.horizontal, PGSpacing.sm)
                .padding(.vertical, PGSpacing.xs)
                .background(isSelected ? Color.pgPrimary : Color.pgSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AssetsListView()
        .modelContainer(for: Asset.self, inMemory: true)
}
