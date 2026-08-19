// MARK: - AssetCard.swift
// PersonalGuide
//
// Reusable card for displaying an Asset with its warranty status,
// active case indicators, and asset metadata.

import SwiftUI

struct AssetCard: View {

    let asset: Asset

    var body: some View {
        PGCard {
            VStack(alignment: .leading, spacing: PGSpacing.sm) {
                // Header
                HStack {
                    Image(systemName: asset.assetType.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(.pgPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.pgSurface)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(asset.name)
                            .font(.pgSubtitle)
                            .foregroundStyle(.pgTextPrimary)
                            .lineLimit(1)

                        if let mfr = asset.manufacturer {
                            Text(mfr + (asset.modelNumber != nil ? " • \(asset.modelNumber!)" : ""))
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Warranty Status
                    if asset.isUnderWarranty {
                        Text("Under Warranty")
                            .font(.pgSmallLabel)
                            .foregroundStyle(.pgPositive)
                            .padding(.horizontal, PGSpacing.xs)
                            .padding(.vertical, 4)
                            .background(Color.pgPositive.opacity(0.12))
                            .clipShape(Capsule())
                    } else if asset.warrantyEndDate != nil {
                        Text("Warranty Expired")
                            .font(.pgSmallLabel)
                            .foregroundStyle(.pgTextSecondary)
                            .padding(.horizontal, PGSpacing.xs)
                            .padding(.vertical, 4)
                            .background(Color.pgSurface)
                            .clipShape(Capsule())
                    }
                }

                // Metadata Details
                HStack(spacing: PGSpacing.md) {
                    if let serial = asset.serialNumber, !serial.isEmpty {
                        HStack(spacing: 4) {
                            Text("S/N:")
                                .font(.pgSmallLabel)
                                .foregroundStyle(.pgTextSecondary)
                            Text(serial)
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextPrimary)
                        }
                    }

                    Spacer()

                    if !asset.cases.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.pgPrimary)
                            Text("\(asset.cases.count) \(asset.cases.count == 1 ? "case" : "cases")")
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextPrimary)
                        }
                    }
                }
            }
        }
    }
}
