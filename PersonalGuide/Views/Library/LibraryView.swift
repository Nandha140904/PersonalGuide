// MARK: - LibraryView.swift
// PersonalGuide
//
// "Everything in one place."
// Search, filter, browse all cases, documents, and assets.

import SwiftUI
import SwiftData

struct LibraryView: View {

    @Query(sort: \PGCase.updatedAt, order: .reverse)
    private var allCases: [PGCase]

    @State private var searchText = ""
    @State private var selectedFilter: LibraryFilter = .all

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

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.pgTextSecondary)
                    TextField("Search your guide", text: $searchText)
                        .font(.pgBody)
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

                // Results
                if filteredCases.isEmpty {
                    Spacer()
                    PGEmptyState(
                        icon: "tray",
                        title: searchText.isEmpty ? "No cases yet" : "No results",
                        message: searchText.isEmpty
                            ? "Cases you create will appear here."
                            : "Try a different search term."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(filteredCases) { pgCase in
                            NavigationLink(value: pgCase) {
                                LibraryCaseRow(pgCase: pgCase)
                            }
                            .listRowBackground(Color.pgBackground)
                            .listRowSeparatorTint(.pgBorder)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.pgBackground)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: PGCase.self) { pgCase in
                CaseDetailView(pgCase: pgCase)
            }
        }
    }

    // MARK: - Filtering

    private var filteredCases: [PGCase] {
        var cases = allCases

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .cases:
            cases = cases.filter { $0.status.isOpen }
        case .documents:
            cases = cases.filter { !$0.documents.isEmpty }
        case .purchases:
            cases = cases.filter { $0.caseType == .purchaseReturn }
        case .bills:
            cases = cases.filter { $0.caseType == .subscriptionBill }
        case .subscriptions:
            cases = cases.filter { $0.caseType == .subscriptionBill }
        case .completed:
            cases = cases.filter { $0.status == .completed || $0.status == .archived }
        }

        // Apply search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            cases = cases.filter { pgCase in
                pgCase.title.lowercased().contains(query) ||
                pgCase.descriptionText.lowercased().contains(query) ||
                pgCase.category?.lowercased().contains(query) == true ||
                pgCase.caseType.displayName.lowercased().contains(query)
            }
        }

        return cases
    }
}

// MARK: - Library Filter

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
    case cases
    case documents
    case purchases
    case bills
    case subscriptions
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:           return "All"
        case .cases:         return "Cases"
        case .documents:     return "Documents"
        case .purchases:     return "Purchases"
        case .bills:         return "Bills"
        case .subscriptions: return "Subscriptions"
        case .completed:     return "Completed"
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
            // Type icon
            Image(systemName: pgCase.caseType.iconName)
                .font(.system(size: 18))
                .foregroundStyle(.pgPrimary)
                .frame(width: 36, height: 36)
                .background(Color.pgSurface)
                .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))

            // Info
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

#Preview {
    LibraryView()
        .modelContainer(for: PGCase.self, inMemory: true)
}
