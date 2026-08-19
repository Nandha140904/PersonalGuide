// MARK: - LibraryView.swift
// PersonalGuide
//
// "Everything in one place."
// Live relationship-aware search across Cases, Documents (OCR), Assets, and Actions.

import SwiftUI
import SwiftData

struct LibraryView: View {

    @Query(sort: \PGCase.updatedAt, order: .reverse)
    private var allCases: [PGCase]

    @Query(sort: \PGDocument.createdAt, order: .reverse)
    private var allDocuments: [PGDocument]

    @Query(sort: \Asset.updatedAt, order: .reverse)
    private var allAssets: [Asset]

    @Environment(SearchService.self) private var searchService
    @Environment(CaseService.self) private var caseService
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedFilter: LibraryFilter = .all
    @State private var showCreateAsset = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: PGSpacing.xs) {
                    Text("Everything in one place.")
                        .font(.pgCaption)
                        .foregroundStyle(.pgTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PGSpacing.md)
                .padding(.top, PGSpacing.sm)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.pgTextSecondary)
                    TextField("Search cases, OCR text, assets...", text: $searchText)
                        .font(.pgBody)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.pgTextSecondary)
                        }
                    }
                }
                .padding(PGSpacing.sm)
                .background(Color.pgSurface)
                .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
                .padding(.horizontal, PGSpacing.md)
                .padding(.top, PGSpacing.sm)

                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PGSpacing.xs) {
                        ForEach(LibraryFilter.allCases) { filter in
                            FilterPill(
                                title: filter.displayName,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.pgQuick) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, PGSpacing.md)
                }
                .padding(.top, PGSpacing.sm)

                Divider()
                    .padding(.top, PGSpacing.sm)

                // Content
                if !searchText.isEmpty {
                    searchResultsView
                } else {
                    categoryContentView
                }
            }
            .background(Color.pgBackground)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedFilter == .assets {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateAsset = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.pgPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateAsset) {
                CreateAssetView()
            }
        }
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        let results = searchService.search(
            query: searchText,
            allCases: allCases,
            allDocuments: allDocuments,
            allAssets: allAssets
        )

        return Group {
            if results.isEmpty {
                Spacer()
                PGEmptyState(
                    icon: "magnifyingglass",
                    title: "No results for \"\(searchText)\"",
                    message: "Try searching with a different keyword, issuer, or model number."
                )
                Spacer()
            } else {
                List {
                    // Cases Section
                    if !results.cases.isEmpty {
                        Section("Cases (\(results.cases.count))") {
                            ForEach(results.cases) { pgCase in
                                NavigationLink(destination: CaseDetailView(pgCase: pgCase)) {
                                    LibraryCaseRow(pgCase: pgCase)
                                }
                                .listRowBackground(Color.pgBackground)
                            }
                        }
                    }

                    // Documents (OCR) Section
                    if !results.documents.isEmpty {
                        Section("Documents & OCR (\(results.documents.count))") {
                            ForEach(results.documents) { doc in
                                HStack(spacing: PGSpacing.sm) {
                                    Image(systemName: doc.documentType.iconName)
                                        .foregroundStyle(.pgPrimary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(doc.fileName)
                                            .font(.pgBody)
                                            .foregroundStyle(.pgTextPrimary)
                                        if let text = doc.extractedText, !text.isEmpty {
                                            Text(text.prefix(80) + "...")
                                                .font(.pgCaption)
                                                .foregroundStyle(.pgTextSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .listRowBackground(Color.pgBackground)
                            }
                        }
                    }

                    // Assets Section
                    if !results.assets.isEmpty {
                        Section("Assets (\(results.assets.count))") {
                            ForEach(results.assets) { asset in
                                NavigationLink(destination: AssetDetailView(asset: asset)) {
                                    AssetCard(asset: asset)
                                }
                                .listRowBackground(Color.pgBackground)
                            }
                        }
                    }

                    // Actions Section
                    if !results.actions.isEmpty {
                        Section("Action Steps (\(results.actions.count))") {
                            ForEach(results.actions, id: \.action.id) { pair in
                                NavigationLink(destination: CaseDetailView(pgCase: pair.parentCase)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pair.action.title)
                                            .font(.pgBody)
                                            .foregroundStyle(.pgTextPrimary)
                                        Text("In \(pair.parentCase.title)")
                                            .font(.pgCaption)
                                            .foregroundStyle(.pgTextSecondary)
                                    }
                                }
                                .listRowBackground(Color.pgBackground)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Category View

    private var categoryContentView: some View {
        Group {
            if selectedFilter == .assets {
                if allAssets.isEmpty {
                    Spacer()
                    PGEmptyState(
                        icon: "cube.box",
                        title: "No assets added",
                        message: "Add your car, phone, laptop, or appliances to track warranties and maintenance.",
                        actionTitle: "Add an asset",
                        action: { showCreateAsset = true }
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(allAssets) { asset in
                            NavigationLink(destination: AssetDetailView(asset: asset)) {
                                AssetCard(asset: asset)
                            }
                            .listRowBackground(Color.pgBackground)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            } else {
                let cases = filteredCases
                if cases.isEmpty {
                    Spacer()
                    PGEmptyState(
                        icon: "tray",
                        title: "No cases in \(selectedFilter.displayName)",
                        message: "Cases you create will appear here."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(cases) { pgCase in
                            NavigationLink(destination: CaseDetailView(pgCase: pgCase)) {
                                LibraryCaseRow(pgCase: pgCase)
                            }
                            .listRowBackground(Color.pgBackground)
                            .listRowSeparatorTint(.pgBorder)
                            .swipeActions(edge: .trailing) {
                                if pgCase.status.isOpen {
                                    Button {
                                        try? caseService.completeCase(pgCase, in: modelContext)
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.pgPositive)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    // MARK: - Filtered Cases

    private var filteredCases: [PGCase] {
        switch selectedFilter {
        case .all:
            return allCases
        case .cases:
            return allCases.filter { $0.status.isOpen }
        case .assets:
            return allCases
        case .purchases:
            return allCases.filter { $0.caseType == .purchaseReturn }
        case .bills:
            return allCases.filter { $0.caseType == .subscriptionBill }
        case .completed:
            return allCases.filter { $0.status == .completed || $0.status == .archived }
        }
    }
}

// MARK: - Library Filter

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
    case cases
    case assets
    case purchases
    case bills
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:       return "All"
        case .cases:     return "Cases"
        case .assets:    return "Assets"
        case .purchases: return "Purchases"
        case .bills:     return "Bills"
        case .completed: return "Completed"
        }
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pgSmallLabel)
                .foregroundStyle(isSelected ? .white : .pgTextPrimary)
                .padding(.horizontal, PGSpacing.sm)
                .padding(.vertical, PGSpacing.xs)
                .background(isSelected ? Color.pgPrimary : Color.pgSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Case Row

private struct LibraryCaseRow: View {
    let pgCase: PGCase

    var body: some View {
        HStack(spacing: PGSpacing.sm) {
            Image(systemName: pgCase.caseType.iconName)
                .font(.system(size: 18))
                .foregroundStyle(.pgPrimary)
                .frame(width: 36, height: 36)
                .background(Color.pgSurface)
                .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))

            VStack(alignment: .leading, spacing: 2) {
                Text(pgCase.title)
                    .font(.pgBody)
                    .foregroundStyle(.pgTextPrimary)
                    .lineLimit(1)

                HStack(spacing: PGSpacing.xs) {
                    Text(pgCase.caseType.shortLabel)
                        .font(.pgSmallLabel)
                        .foregroundStyle(.pgTextSecondary)

                    if let deadline = pgCase.deadline {
                        Text("·")
                            .foregroundStyle(.pgTextSecondary)
                        DeadlineLabel(deadline: deadline)
                    }
                }
            }

            Spacer()

            PGStatusBadge(status: pgCase.status)
        }
        .padding(.vertical, PGSpacing.xxs)
    }
}
