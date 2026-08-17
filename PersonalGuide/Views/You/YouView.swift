// MARK: - YouView.swift
// PersonalGuide
//
// Profile & settings — privacy status, storage, notifications,
// export, delete, security, feedback.
// "Private by default — your data stays on this device."

import SwiftUI
import SwiftData

struct YouView: View {

    @Query private var allCases: [PGCase]
    @Query private var allDocuments: [PGDocument]

    @State private var showExport = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Privacy Badge
                Section {
                    HStack(spacing: PGSpacing.sm) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.pgPositive)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Private by default")
                                .font(.pgSubtitle)
                                .foregroundStyle(.pgTextPrimary)
                            Text("Your data stays on this device. Cloud backup can be added when you choose.")
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                        }
                    }
                    .padding(.vertical, PGSpacing.xs)
                }
                .listRowBackground(Color.pgSurface)

                // MARK: - Stats
                Section("Your guide") {
                    StatRow(icon: "folder.fill", label: "Total cases", value: "\(allCases.count)")
                    StatRow(icon: "checkmark.seal.fill", label: "Completed", value: "\(completedCount)")
                    StatRow(icon: "doc.fill", label: "Documents", value: "\(allDocuments.count)")
                }

                // MARK: - Storage
                Section("Storage") {
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundStyle(.pgPrimary)
                        Text("Local storage")
                        Spacer()
                        Text("On this device")
                            .font(.pgCaption)
                            .foregroundStyle(.pgPositive)
                    }

                    HStack {
                        Image(systemName: "icloud")
                            .foregroundStyle(.pgTextSecondary)
                        Text("iCloud sync")
                        Spacer()
                        Text("Off")
                            .font(.pgCaption)
                            .foregroundStyle(.pgTextSecondary)
                    }
                }

                // MARK: - Notifications
                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notification preferences", systemImage: "bell")
                    }
                }

                // MARK: - Data
                Section("Your data") {
                    Button {
                        showExport = true
                    } label: {
                        Label("Export all data", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(.pgTextPrimary)

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete all data", systemImage: "trash")
                    }
                    .foregroundStyle(.pgCritical)
                }

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.pgTextSecondary)
                    }

                    NavigationLink {
                        // Future: feedback form
                        Text("Feedback")
                    } label: {
                        Label("Send feedback", systemImage: "bubble.left")
                    }

                    NavigationLink {
                        // Future: help/FAQ
                        Text("Help")
                    } label: {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.pgBackground)
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete all data?", isPresented: $showDeleteConfirmation) {
                Button("Delete everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your cases, documents, and settings. This cannot be undone.")
            }
            .sheet(isPresented: $showExport) {
                ExportDataView()
            }
        }
    }

    // MARK: - Computed

    private var completedCount: Int {
        allCases.filter { $0.status == .completed }.count
    }

    // MARK: - Actions

    private func deleteAllData() {
        // Phase 4: Implement full data deletion
        // This will cascade-delete all SwiftData entities and local document files
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.pgPrimary)
            Text(label)
            Spacer()
            Text(value)
                .font(.pgMono)
                .foregroundStyle(.pgTextSecondary)
        }
    }
}

// MARK: - Notification Settings (placeholder)

struct NotificationSettingsView: View {
    @State private var deadlineReminders = true
    @State private var actionReminders = true

    var body: some View {
        List {
            Section("Reminders") {
                Toggle("Deadline reminders", isOn: $deadlineReminders)
                    .tint(.pgPrimary)
                Toggle("Action reminders", isOn: $actionReminders)
                    .tint(.pgPrimary)
            }

            Section(footer: Text("Personal Guide sends action-oriented notifications — not just 'Reminder: X'. Each notification tells you what to do next.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Export Data (placeholder)

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: PGSpacing.lg) {
                PGEmptyState(
                    icon: "square.and.arrow.up",
                    title: "Export your data",
                    message: "Download all your cases, documents, and settings as a portable archive.",
                    actionTitle: "Export now",
                    action: {
                        // Phase 4: Implement JSON + documents export
                    }
                )
            }
            .background(Color.pgBackground)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    YouView()
        .modelContainer(for: PGCase.self, inMemory: true)
}
