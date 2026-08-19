// MARK: - Asset.swift
// PersonalGuide
//
// Assets connect multiple pieces of life administration.
// A car has insurance, registration, service history, warranty.
// A phone has purchase receipt, warranty, repair history.
// This relationship graph is a long-term product differentiator.

import Foundation
import SwiftData

@Model
final class Asset {

    var id: UUID
    var name: String
    var descriptionText: String
    var assetTypeRaw: String

    /// Purchase date of the asset.
    var purchaseDate: Date?

    /// Warranty expiration date if applicable.
    var warrantyEndDate: Date?

    /// Arbitrary metadata (JSON-encoded) — e.g., make, model, serial number.
    var metadataJSON: String?

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    @Relationship(deleteRule: .nullify, inverse: \PGCase.relatedAsset)
    var cases: [PGCase] = []

    // MARK: - Init

    init(
        name: String,
        assetType: AssetType = .other,
        descriptionText: String = "",
        purchaseDate: Date? = nil,
        warrantyEndDate: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.assetTypeRaw = assetType.rawValue
        self.descriptionText = descriptionText
        self.purchaseDate = purchaseDate
        self.warrantyEndDate = warrantyEndDate
        self.createdAt = .now
        self.updatedAt = .now
    }

    // MARK: - Computed

    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRaw) ?? .other }
        set {
            assetTypeRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    var metadata: [String: String] {
        get {
            guard let json = metadataJSON,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let json = String(data: data, encoding: .utf8)
            else { return }
            metadataJSON = json
        }
    }

    var manufacturer: String? {
        get { metadata["manufacturer"] }
        set {
            var meta = metadata
            meta["manufacturer"] = newValue
            metadata = meta
        }
    }

    var modelNumber: String? {
        get { metadata["modelNumber"] }
        set {
            var meta = metadata
            meta["modelNumber"] = newValue
            metadata = meta
        }
    }

    var serialNumber: String? {
        get { metadata["serialNumber"] }
        set {
            var meta = metadata
            meta["serialNumber"] = newValue
            metadata = meta
        }
    }

    /// Whether the asset is currently within its active warranty period.
    var isUnderWarranty: Bool {
        guard let warrantyEndDate else { return false }
        return warrantyEndDate > .now
    }

    /// Number of active cases linked to this asset.
    var activeCaseCount: Int {
        cases.filter { $0.status.isOpen }.count
    }
}
