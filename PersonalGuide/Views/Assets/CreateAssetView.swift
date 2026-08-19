// MARK: - CreateAssetView.swift
// PersonalGuide
//
// Form for adding a new asset (vehicle, smartphone, appliance, etc.) to the user's registry.

import SwiftUI
import SwiftData

struct CreateAssetView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedType: AssetType = .phone
    @State private var manufacturer = ""
    @State private var modelNumber = ""
    @State private var serialNumber = ""
    @State private var notes = ""

    // Dates
    @State private var hasPurchaseDate = false
    @State private var purchaseDate = Date.now
    @State private var hasWarranty = false
    @State private var warrantyEndDate = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basics
                Section("Asset Details") {
                    TextField("Asset Name (e.g. iPhone 14 Pro, Honda City)", text: $name)
                        .font(.pgBody)

                    Picker("Type", selection: $selectedType) {
                        ForEach(AssetType.allCases) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                }

                // MARK: - Hardware / Maker
                Section("Manufacturer & Identifiers") {
                    TextField("Brand / Maker (e.g. Apple, Sony, Samsung)", text: $manufacturer)
                        .font(.pgBody)

                    TextField("Model Number (optional)", text: $modelNumber)
                        .font(.pgBody)

                    TextField("Serial Number / IMEI / Reg #", text: $serialNumber)
                        .font(.pgBody)
                }

                // MARK: - Purchase & Warranty
                Section("Purchase & Warranty") {
                    Toggle("Has Purchase Date", isOn: $hasPurchaseDate)
                    if hasPurchaseDate {
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: [.date])
                    }

                    Toggle("Has Warranty Coverage", isOn: $hasWarranty)
                    if hasWarranty {
                        DatePicker("Warranty Expiry Date", selection: $warrantyEndDate, displayedComponents: [.date])
                    }
                }

                // MARK: - Notes
                Section("Notes") {
                    TextField("Any additional details...", text: $notes, axis: .vertical)
                        .font(.pgBody)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("New Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.pgTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAsset()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(.pgPrimary)
                }
            }
        }
    }

    private func saveAsset() {
        let asset = Asset(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            assetType: selectedType,
            descriptionText: notes,
            purchaseDate: hasPurchaseDate ? purchaseDate : nil,
            warrantyEndDate: hasWarranty ? warrantyEndDate : nil
        )

        if !manufacturer.isEmpty {
            asset.manufacturer = manufacturer.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if !modelNumber.isEmpty {
            asset.modelNumber = modelNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if !serialNumber.isEmpty {
            asset.serialNumber = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        modelContext.insert(asset)
        try? modelContext.save()
    }
}

#Preview {
    CreateAssetView()
        .modelContainer(for: Asset.self, inMemory: true)
}
