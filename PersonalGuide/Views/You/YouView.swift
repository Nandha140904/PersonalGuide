// MARK: - YouView.swift
// PersonalGuide
//
// Profile & settings — privacy status, AI engine selection, storage, notifications,
// export, delete, security, feedback.
// "Private by default — your data stays on this device."

import SwiftUI
import SwiftData

struct YouView: View {

    @Environment(AIService.self) private var aiService
    @Environment(NotificationManager.self) private var notificationManager
    @Query private var allCases: [PGCase]
    @Query private var allDocuments: [PGDocument]
    @Query private var allAssets: [Asset]

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
                            Text("Your data stays on this device. OCR runs 100% locally with Apple Vision.")
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
                    StatRow(icon: "cube.box.fill", label: "Assets", value: "\(allAssets.count)")
                }

                // MARK: - AI & Intelligence
                Section("AI & Intelligence") {
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        HStack {
                            Label("Intelligence Engine", systemImage: "sparkles")
                            Spacer()
                            Text(aiService.activeProviderType.displayName)
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                        }
                    }
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
                        HStack {
                            Label("Notification preferences", systemImage: "bell")
                            Spacer()
                            Text(notificationManager.isAuthorized ? "Enabled" : "Disabled")
                                .font(.pgCaption)
                                .foregroundStyle(notificationManager.isAuthorized ? .pgPositive : .pgTextSecondary)
                        }
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
                        Text("Personal Guide v1.0.0\nDesigned for iPhone 14 Pro.")
                            .font(.pgBody)
                            .padding()
                    } label: {
                        Label("About Personal Guide", systemImage: "info.circle")
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
        // Cascade delete placeholder
    }
}

// MARK: - AI Settings View

struct AISettingsView: View {
    @Environment(AIService.self) private var aiService

    var body: some View {
        @Bindable var service = aiService

        List {
            Section("Active Engine") {
                Picker("AI Provider", selection: $service.activeProviderType) {
                    ForEach(AIProviderType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.inline)
            }

            if service.activeProviderType == .gemini {
                Section("Google Gemini API Key") {
                    SecureField("Enter Gemini API Key", text: $service.geminiApiKey)
                        .font(.pgBody)
                }
            } else if service.activeProviderType == .openAI {
                Section("OpenAI API Key") {
                    SecureField("Enter OpenAI API Key", text: $service.openAIApiKey)
                        .font(.pgBody)
                }
            }

            Section(footer: Text("On-Device AI runs 100% locally on your iPhone using Apple Vision and NaturalLanguage. No data ever leaves your device.")) {
                EmptyView()
            }
        }
        .navigationTitle("AI Engine")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @Environment(NotificationManager.self) private var notificationManager

    @State private var deadlineReminders = true
    @State private var actionReminders = true

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Permission")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Label("Authorized", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.pgPositive)
                    } else {
                        Button("Enable in Settings") {
                            Task {
                                _ = await notificationManager.requestAuthorization()
                            }
                        }
                        .foregroundStyle(.pgPrimary)
                    }
                }
            }

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

// MARK: - Export Data

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
                    action: {}
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
        .environment(AIService())
        .environment(NotificationManager.shared)
}
