// MARK: - AssetDetailView.swift
// PersonalGuide
//
// Workspace for a specific asset — viewing its history, linked cases,
// warranties, documents, and creating new linked cases.

import SwiftUI
import SwiftData

struct AssetDetailView: View {

    @Bindable var asset: Asset
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateCase = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PGSpacing.lg) {

                // MARK: - Hero Header
                PGCard {
                    VStack(alignment: .leading, spacing: PGSpacing.md) {
                        HStack {
                            Image(systemName: asset.assetType.iconName)
                                .font(.system(size: 28))
                                .foregroundStyle(.pgPrimary)
                                .frame(width: 48, height: 48)
                                .background(Color.pgSurface)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.name)
                                    .font(.pgHero)
                                    .foregroundStyle(.pgTextPrimary)

                                if let mfr = asset.manufacturer {
                                    Text(mfr + (asset.modelNumber != nil ? " • \(asset.modelNumber!)" : ""))
                                        .font(.pgSubtitle)
                                        .foregroundStyle(.pgTextSecondary)
                                }
                            }
                            Spacer()
                        }

                        // Warranty Status Pill
                        if asset.isUnderWarranty, let warrantyEnd = asset.warrantyEndDate {
                            HStack(spacing: PGSpacing.xs) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.pgPositive)
                                Text("Warranty active until \(warrantyEnd.shortFormatted)")
                                    .font(.pgCaption)
                                    .foregroundStyle(.pgPositive)
                            }
                            .padding(PGSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.pgPositive.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))
                        }
                    }
                }

                // MARK: - Key Identifiers
                VStack(alignment: .leading, spacing: PGSpacing.xs) {
                    PGSectionHeader("Identifiers & Info")

                    PGCard {
                        VStack(spacing: PGSpacing.sm) {
                            if let serial = asset.serialNumber, !serial.isEmpty {
                                infoRow(title: "Serial / IMEI Number", value: serial)
                            }

                            if let purchaseDate = asset.purchaseDate {
                                if asset.serialNumber != nil { PGDivider() }
                                infoRow(title: "Purchased", value: purchaseDate.shortFormatted)
                            }

                            if let warrantyDate = asset.warrantyEndDate {
                                PGDivider()
                                infoRow(title: "Warranty Expiry", value: warrantyDate.shortFormatted)
                            }
                        }
                    }
                }

                // MARK: - Linked Cases
                VStack(alignment: .leading, spacing: PGSpacing.xs) {
                    HStack {
                        PGSectionHeader("Linked Cases (\(asset.cases.count))")
                        Spacer()
                        Button {
                            showCreateCase = true
                        } label: {
                            Label("New Case", systemImage: "plus")
                                .font(.pgSmallLabel)
                                .foregroundStyle(.pgPrimary)
                        }
                    }

                    if asset.cases.isEmpty {
                        PGEmptyState(
                            icon: "folder.badge.questionmark",
                            title: "No linked cases",
                            message: "Start a return, warranty claim, insurance renewal, or service case for this \(asset.name).",
                            actionTitle: "Create case for this asset",
                            action: { showCreateCase = true }
                        )
                    } else {
                        ForEach(asset.cases) { pgCase in
                            NavigationLink(destination: CaseDetailView(pgCase: pgCase)) {
                                PGCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(pgCase.title)
                                                .font(.pgSubtitle)
                                                .foregroundStyle(.pgTextPrimary)
                                            Text(pgCase.caseType.displayName)
                                                .font(.pgCaption)
                                                .foregroundStyle(.pgTextSecondary)
                                        }
                                        Spacer()
                                        PGStatusBadge(status: pgCase.status)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // MARK: - Notes
                if !asset.descriptionText.isEmpty {
                    VStack(alignment: .leading, spacing: PGSpacing.xs) {
                        PGSectionHeader("Notes")
                        PGCard {
                            Text(asset.descriptionText)
                                .font(.pgBody)
                                .foregroundStyle(.pgTextPrimary)
                        }
                    }
                }
            }
            .padding(.horizontal, PGSpacing.md)
            .padding(.bottom, PGSpacing.xxl)
        }
        .background(Color.pgBackground)
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateCase) {
            CreateCaseView()
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.pgBody)
                .foregroundStyle(.pgTextSecondary)
            Spacer()
            Text(value)
                .font(.pgBody)
                .foregroundStyle(.pgTextPrimary)
        }
    }
}
