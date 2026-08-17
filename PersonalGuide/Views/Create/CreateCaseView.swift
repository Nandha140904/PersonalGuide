// MARK: - CreateCaseView.swift
// PersonalGuide
//
// Three paths to create a case:
// 1. Tell Guide — natural language input
// 2. Scan — camera/document (Phase 2)
// 3. Add manually — structured form
//
// After input, the system shows a preview for confirmation.

import SwiftUI
import SwiftData

struct CreateCaseView: View {

    @Environment(CaseService.self) private var caseService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPath: CreatePath = .tell
    @State private var showPreview = false
    @State private var draft = CaseDraft()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Path selector
                pathSelector
                    .padding(.horizontal, PGSpacing.md)
                    .padding(.top, PGSpacing.md)

                Divider()
                    .padding(.top, PGSpacing.md)

                // Content based on selected path
                ScrollView {
                    switch selectedPath {
                    case .tell:
                        tellGuideContent
                    case .scan:
                        scanContent
                    case .manual:
                        manualContent
                    }
                }
            }
            .background(Color.pgBackground)
            .navigationTitle("New case")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.pgTextSecondary)
                }
            }
            .sheet(isPresented: $showPreview) {
                CasePreviewView(draft: draft) { confirmedDraft in
                    createCase(from: confirmedDraft)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Path Selector

    private var pathSelector: some View {
        HStack(spacing: PGSpacing.xs) {
            ForEach(CreatePath.allCases) { path in
                Button {
                    withAnimation(.pgQuick) {
                        selectedPath = path
                    }
                } label: {
                    VStack(spacing: PGSpacing.xxs) {
                        Image(systemName: path.icon)
                            .font(.system(size: 18))
                        Text(path.label)
                            .font(.pgSmallLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PGSpacing.sm)
                    .foregroundStyle(selectedPath == path ? .white : .pgTextPrimary)
                    .background(selectedPath == path ? Color.pgPrimary : Color.pgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tell Guide

    @State private var naturalLanguageInput = ""

    private var tellGuideContent: some View {
        VStack(alignment: .leading, spacing: PGSpacing.lg) {
            VStack(alignment: .leading, spacing: PGSpacing.xs) {
                Text("Tell me what you need to get done")
                    .font(.pgTitle)
                    .foregroundStyle(.pgTextPrimary)

                Text("Describe it however you like. I'll figure out the rest.")
                    .font(.pgBody)
                    .foregroundStyle(.pgTextSecondary)
            }

            TextEditor(text: $naturalLanguageInput)
                .font(.pgBody)
                .frame(minHeight: 120)
                .padding(PGSpacing.sm)
                .background(Color.pgCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: PGRadius.medium)
                        .strokeBorder(Color.pgBorder, lineWidth: 1)
                }
                .overlay(alignment: .topLeading) {
                    if naturalLanguageInput.isEmpty {
                        Text("e.g., I need to renew my car insurance...")
                            .font(.pgBody)
                            .foregroundStyle(.pgTextSecondary.opacity(0.5))
                            .padding(PGSpacing.md)
                            .allowsHitTesting(false)
                    }
                }

            // Suggestions
            VStack(alignment: .leading, spacing: PGSpacing.xs) {
                Text("Try something like:")
                    .font(.pgCaption)
                    .foregroundStyle(.pgTextSecondary)

                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        naturalLanguageInput = suggestion
                    } label: {
                        Text(suggestion)
                            .font(.pgCaption)
                            .foregroundStyle(.pgPrimary)
                            .padding(.horizontal, PGSpacing.sm)
                            .padding(.vertical, PGSpacing.xs)
                            .background(Color.pgSurface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            PGButton("Continue", icon: "sparkles") {
                draft = CaseDraft.fromNaturalLanguage(naturalLanguageInput)
                showPreview = true
            }
            .disabled(naturalLanguageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(naturalLanguageInput.isEmpty ? 0.5 : 1)
        }
        .padding(PGSpacing.md)
    }

    private var suggestions: [String] {
        [
            "I need to renew my car insurance",
            "Return the headphones I bought on Amazon",
            "My passport expires next month",
            "Cancel my Netflix subscription",
        ]
    }

    // MARK: - Scan (Phase 2 placeholder)

    private var scanContent: some View {
        VStack(spacing: PGSpacing.lg) {
            PGEmptyState(
                icon: "doc.viewfinder",
                title: "Scan a document",
                message: "Upload a receipt, bill, policy, or any document. Personal Guide will extract the details and create a case for you.",
                actionTitle: "Choose file",
                action: {
                    // Phase 2: VisionKit document scanner
                }
            )
        }
        .padding(PGSpacing.md)
    }

    // MARK: - Manual

    @State private var manualTitle = ""
    @State private var manualType: CaseType = .genericLifeAdmin
    @State private var manualDeadline: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var hasDeadline = false
    @State private var manualDescription = ""

    private var manualContent: some View {
        VStack(alignment: .leading, spacing: PGSpacing.lg) {
            VStack(alignment: .leading, spacing: PGSpacing.xs) {
                Text("What do you need to get done?")
                    .font(.pgTitle)
                    .foregroundStyle(.pgTextPrimary)
            }

            // Title
            VStack(alignment: .leading, spacing: PGSpacing.xxs) {
                Text("Title")
                    .font(.pgCaption)
                    .foregroundStyle(.pgTextSecondary)
                TextField("e.g., Renew car insurance", text: $manualTitle)
                    .font(.pgBody)
                    .padding(PGSpacing.sm)
                    .background(Color.pgCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))
                    .overlay {
                        RoundedRectangle(cornerRadius: PGRadius.small)
                            .strokeBorder(Color.pgBorder, lineWidth: 1)
                    }
            }

            // Type
            VStack(alignment: .leading, spacing: PGSpacing.xxs) {
                Text("Type")
                    .font(.pgCaption)
                    .foregroundStyle(.pgTextSecondary)
                Picker("Case type", selection: $manualType) {
                    ForEach(CaseType.allCases) { type in
                        Label(type.displayName, systemImage: type.iconName)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(.pgPrimary)
            }

            // Deadline
            Toggle(isOn: $hasDeadline) {
                Text("Has a deadline")
                    .font(.pgBody)
                    .foregroundStyle(.pgTextPrimary)
            }
            .tint(.pgPrimary)

            if hasDeadline {
                DatePicker(
                    "Deadline",
                    selection: $manualDeadline,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .tint(.pgPrimary)
            }

            // Description
            VStack(alignment: .leading, spacing: PGSpacing.xxs) {
                Text("Notes (optional)")
                    .font(.pgCaption)
                    .foregroundStyle(.pgTextSecondary)
                TextField("Any details you want to add...", text: $manualDescription, axis: .vertical)
                    .font(.pgBody)
                    .lineLimit(3...6)
                    .padding(PGSpacing.sm)
                    .background(Color.pgCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))
                    .overlay {
                        RoundedRectangle(cornerRadius: PGRadius.small)
                            .strokeBorder(Color.pgBorder, lineWidth: 1)
                    }
            }

            Spacer()

            PGButton("Create case", icon: "plus") {
                draft = CaseDraft(
                    title: manualTitle,
                    descriptionText: manualDescription,
                    caseType: manualType,
                    source: .manualEntry,
                    deadline: hasDeadline ? manualDeadline : nil
                )
                createCase(from: draft)
                dismiss()
            }
            .disabled(manualTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(manualTitle.isEmpty ? 0.5 : 1)
        }
        .padding(PGSpacing.md)
    }

    // MARK: - Case Creation

    private func createCase(from draft: CaseDraft) {
        let pgCase = caseService.createCase(
            title: draft.title,
            descriptionText: draft.descriptionText,
            caseType: draft.caseType,
            source: draft.source,
            deadline: draft.deadline,
            priority: draft.priority,
            actions: draft.actions,
            requirements: draft.requirements,
            in: modelContext
        )

        // Auto-activate if not a draft
        try? caseService.activateCase(pgCase, in: modelContext)
    }
}

// MARK: - Create Path

enum CreatePath: String, CaseIterable, Identifiable {
    case tell
    case scan
    case manual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tell:   return "Tell Guide"
        case .scan:   return "Scan"
        case .manual: return "Add"
        }
    }

    var icon: String {
        switch self {
        case .tell:   return "text.bubble"
        case .scan:   return "doc.viewfinder"
        case .manual: return "plus.rectangle"
        }
    }
}

// MARK: - Case Draft

/// Lightweight draft model used during the creation flow before committing to SwiftData.
struct CaseDraft {
    var title: String = ""
    var descriptionText: String = ""
    var caseType: CaseType = .genericLifeAdmin
    var source: CaseSource = .manualEntry
    var deadline: Date?
    var priority: CasePriority = .normal
    var confidence: Double = 1.0
    var actions: [CaseActionDraft] = []
    var requirements: [CaseRequirementDraft] = []

    /// Create a draft from natural language input.
    /// In Phase 2, this will call the AI ConversationalInterpreter.
    /// For now, it creates a basic draft from the user's text.
    static func fromNaturalLanguage(_ text: String) -> CaseDraft {
        // Phase 2: Replace with AI-powered interpretation
        var draft = CaseDraft()
        draft.title = text.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines)
        draft.source = .naturalLanguage

        // Simple keyword-based type detection (placeholder for AI classifier)
        let lower = text.lowercased()
        if lower.contains("return") || lower.contains("refund") {
            draft.caseType = .purchaseReturn
        } else if lower.contains("insurance") || lower.contains("warranty") || lower.contains("claim") {
            draft.caseType = .insuranceWarranty
        } else if lower.contains("renew") || lower.contains("passport") || lower.contains("license") || lower.contains("expire") {
            draft.caseType = .documentRenewal
        } else if lower.contains("bill") || lower.contains("subscription") || lower.contains("cancel") || lower.contains("payment") {
            draft.caseType = .subscriptionBill
        }

        draft.confidence = 0.6 // Low confidence for keyword-based detection

        return draft
    }
}

// MARK: - Case Preview

/// Shows the AI-generated (or keyword-detected) case preview for user confirmation.
struct CasePreviewView: View {
    let draft: CaseDraft
    let onConfirm: (CaseDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedDraft: CaseDraft

    init(draft: CaseDraft, onConfirm: @escaping (CaseDraft) -> Void) {
        self.draft = draft
        self.onConfirm = onConfirm
        self._editedDraft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PGSpacing.lg) {
                    // Confidence disclaimer
                    if draft.confidence < 0.8 {
                        HStack(spacing: PGSpacing.sm) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.pgWarning)
                            Text("I think this is what you need. Please review and confirm.")
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                        }
                        .padding(PGSpacing.sm)
                        .background(Color.pgWarning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))
                    }

                    // Preview card
                    PGCard {
                        VStack(alignment: .leading, spacing: PGSpacing.md) {
                            HStack {
                                Image(systemName: editedDraft.caseType.iconName)
                                    .foregroundStyle(.pgPrimary)
                                Text(editedDraft.caseType.displayName)
                                    .font(.pgSmallLabel)
                                    .foregroundStyle(.pgTextSecondary)
                                    .tracking(1)
                            }

                            // Editable title
                            TextField("Title", text: $editedDraft.title)
                                .font(.pgTitle)
                                .foregroundStyle(.pgTextPrimary)

                            // Type picker
                            Picker("Type", selection: $editedDraft.caseType) {
                                ForEach(CaseType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.pgPrimary)
                        }
                    }

                    // Actions
                    PGButton("Create case", icon: "checkmark") {
                        onConfirm(editedDraft)
                        dismiss()
                    }

                    PGButton("Edit more", icon: "pencil", style: .secondary) {
                        dismiss()
                    }
                }
                .padding(PGSpacing.md)
            }
            .background(Color.pgBackground)
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CreateCaseView()
        .modelContainer(for: PGCase.self, inMemory: true)
        .environment(CaseService())
}
