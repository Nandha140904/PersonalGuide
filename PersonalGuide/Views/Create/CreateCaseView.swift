// MARK: - CreateCaseView.swift
// PersonalGuide
//
// Three paths to create a case:
// 1. Tell Guide — natural language AI planning
// 2. Scan — Apple VisionKit camera document scanning & on-device OCR
// 3. Add manually — structured form
//
// After input, the system shows a confidence-tagged preview for confirmation.

import SwiftUI
import SwiftData

struct CreateCaseView: View {

    @Environment(CaseService.self) private var caseService
    @Environment(DocumentService.self) private var documentService
    @Environment(AIService.self) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPath: CreatePath = .tell
    @State private var showPreview = false
    @State private var isProcessingAI = false
    @State private var draft = CaseDraft()

    // Scanner state
    @State private var showDocumentScanner = false
    @State private var scannedDocuments: [PGDocument] = []

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
            .sheet(isPresented: $showDocumentScanner) {
                DocumentScannerView { images in
                    showDocumentScanner = false
                    processScannedImages(images)
                } onCancelled: {
                    showDocumentScanner = false
                }
            }
            .sheet(isPresented: $showPreview) {
                CasePreviewView(draft: draft) { confirmedDraft in
                    createCase(from: confirmedDraft)
                    dismiss()
                }
            }
            .overlay {
                if isProcessingAI {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                        VStack(spacing: PGSpacing.md) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.3)
                            Text("Analyzing & planning case...")
                                .font(.pgSubtitle)
                                .foregroundStyle(.white)
                        }
                        .padding(PGSpacing.xl)
                        .background(Color.pgPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
                        .pgElevatedShadow()
                    }
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

                Text("Describe it however you like. I'll figure out the steps, deadlines, and requirements.")
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
                        Text("e.g., I need to return my headphones on Amazon before the return window closes...")
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

            PGButton("Plan with AI", icon: "sparkles") {
                planWithAI(text: naturalLanguageInput)
            }
            .disabled(naturalLanguageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(naturalLanguageInput.isEmpty ? 0.5 : 1)
        }
        .padding(PGSpacing.md)
    }

    private var suggestions: [String] {
        [
            "Return the headphones I bought on Amazon",
            "Renew my car insurance policy before next week",
            "My passport expires in 2 months",
            "Cancel my Gym membership subscription",
        ]
    }

    // MARK: - Scan

    private var scanContent: some View {
        VStack(spacing: PGSpacing.lg) {
            if scannedDocuments.isEmpty {
                PGEmptyState(
                    icon: "doc.viewfinder",
                    title: "Scan a document",
                    message: "Point your camera at a receipt, policy, bill, or notice. Personal Guide will extract key dates and build your action plan.",
                    actionTitle: "Open Scanner",
                    action: {
                        showDocumentScanner = true
                    }
                )
            } else {
                VStack(alignment: .leading, spacing: PGSpacing.sm) {
                    PGSectionHeader("Scanned pages (\(scannedDocuments.count))")

                    ForEach(scannedDocuments) { doc in
                        PGCard {
                            HStack(spacing: PGSpacing.sm) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(.pgPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.fileName)
                                        .font(.pgBody)
                                        .foregroundStyle(.pgTextPrimary)
                                    Text("\(doc.ocrText.count) characters recognized")
                                        .font(.pgCaption)
                                        .foregroundStyle(.pgTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.pgPositive)
                            }
                        }
                    }

                    PGButton("Scan another page", icon: "plus", style: .secondary) {
                        showDocumentScanner = true
                    }

                    PGButton("Generate Case Plan", icon: "sparkles") {
                        let combinedOCR = scannedDocuments.map { $0.ocrText }.joined(separator: "\n\n")
                        planWithAI(text: combinedOCR, attachedDocs: scannedDocuments)
                    }
                    .padding(.top, PGSpacing.md)
                }
                .padding(PGSpacing.md)
            }
        }
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

    // MARK: - Actions & AI Processing

    private func processScannedImages(_ images: [UIImage]) {
        Task {
            for (idx, image) in images.enumerated() {
                if let doc = try? await documentService.ingestDocument(
                    image: image,
                    fileName: "Scan Page \(scannedDocuments.count + idx + 1)",
                    documentType: .other,
                    in: modelContext
                ) {
                    scannedDocuments.append(doc)
                }
            }
        }
    }

    private func planWithAI(text: String, attachedDocs: [PGDocument] = []) {
        isProcessingAI = true
        Task {
            let plannedDraft = await aiService.planCase(from: text)
            await MainActor.run {
                draft = plannedDraft
                draft.scannedDocuments = attachedDocs
                isProcessingAI = false
                showPreview = true
            }
        }
    }

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

        // Attach scanned documents if any
        for doc in draft.scannedDocuments {
            doc.parentCase = pgCase
        }

        // Auto-activate
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

public struct CaseDraft {
    public var title: String = ""
    public var descriptionText: String = ""
    public var caseType: CaseType = .genericLifeAdmin
    public var documentType: DocumentType = .other
    public var source: CaseSource = .manualEntry
    public var deadline: Date?
    public var priority: CasePriority = .normal
    public var confidence: Double = 1.0
    public var actions: [CaseActionDraft] = []
    public var requirements: [CaseRequirementDraft] = []
    public var scannedDocuments: [PGDocument] = []

    public init(
        title: String = "",
        descriptionText: String = "",
        caseType: CaseType = .genericLifeAdmin,
        documentType: DocumentType = .other,
        source: CaseSource = .manualEntry,
        deadline: Date? = nil,
        priority: CasePriority = .normal,
        confidence: Double = 1.0,
        actions: [CaseActionDraft] = [],
        requirements: [CaseRequirementDraft] = [],
        scannedDocuments: [PGDocument] = []
    ) {
        self.title = title
        self.descriptionText = descriptionText
        self.caseType = caseType
        self.documentType = documentType
        self.source = source
        self.deadline = deadline
        self.priority = priority
        self.confidence = confidence
        self.actions = actions
        self.requirements = requirements
        self.scannedDocuments = scannedDocuments
    }

    public static func fromNaturalLanguage(_ text: String) -> CaseDraft {
        var draft = CaseDraft()
        draft.title = text.prefix(80).trimmingCharacters(in: .whitespacesAndNewlines)
        draft.source = .naturalLanguage

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

        draft.confidence = 0.6
        return draft
    }
}

// MARK: - Case Preview

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
                    // Confidence indicator
                    HStack(spacing: PGSpacing.sm) {
                        Image(systemName: editedDraft.confidence >= 0.8 ? "checkmark.seal.fill" : "sparkles")
                            .foregroundStyle(editedDraft.confidence >= 0.8 ? Color.pgPositive : Color.pgWarning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(editedDraft.confidence >= 0.8 ? "High Confidence Plan" : "Review Recommended")
                                .font(.pgSubtitle)
                                .foregroundStyle(.pgTextPrimary)
                            Text(String(format: "Confidence: %.0f%% — you can adjust anything before creating.", editedDraft.confidence * 100))
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                        }
                    }
                    .padding(PGSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.pgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))

                    // Case summary card
                    PGCard {
                        VStack(alignment: .leading, spacing: PGSpacing.md) {
                            HStack {
                                Image(systemName: editedDraft.caseType.iconName)
                                    .foregroundStyle(.pgPrimary)
                                Text(editedDraft.caseType.displayName)
                                    .font(.pgSmallLabel)
                                    .foregroundStyle(.pgTextSecondary)
                                    .tracking(1)
                                Spacer()
                                PGStatusBadge(priority: editedDraft.priority)
                            }

                            TextField("Title", text: $editedDraft.title)
                                .font(.pgTitle)
                                .foregroundStyle(.pgTextPrimary)

                            if let deadline = editedDraft.deadline {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.pgPrimary)
                                    Text("Deadline: \(deadline.shortFormatted)")
                                        .font(.pgBody)
                                        .foregroundStyle(.pgTextPrimary)
                                }
                            }
                        }
                    }

                    // Steps Preview
                    if !editedDraft.actions.isEmpty {
                        VStack(alignment: .leading, spacing: PGSpacing.xs) {
                            PGSectionHeader("Generated Steps (\(editedDraft.actions.count))")

                            PGCard {
                                VStack(alignment: .leading, spacing: PGSpacing.sm) {
                                    ForEach(editedDraft.actions.indices, id: \.self) { idx in
                                        HStack(spacing: PGSpacing.sm) {
                                            Text("\(idx + 1)")
                                                .font(.pgSmallLabel)
                                                .foregroundStyle(.pgPrimary)
                                                .frame(width: 22, height: 22)
                                                .background(Color.pgSurface)
                                                .clipShape(Circle())

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(editedDraft.actions[idx].title)
                                                    .font(.pgBody)
                                                    .foregroundStyle(.pgTextPrimary)
                                                if !editedDraft.actions[idx].descriptionText.isEmpty {
                                                    Text(editedDraft.actions[idx].descriptionText)
                                                        .font(.pgCaption)
                                                        .foregroundStyle(.pgTextSecondary)
                                                }
                                            }
                                        }
                                        if idx != editedDraft.actions.count - 1 {
                                            PGDivider()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Requirements Preview
                    if !editedDraft.requirements.isEmpty {
                        VStack(alignment: .leading, spacing: PGSpacing.xs) {
                            PGSectionHeader("What you will need (\(editedDraft.requirements.count))")

                            PGCard {
                                VStack(alignment: .leading, spacing: PGSpacing.sm) {
                                    ForEach(editedDraft.requirements.indices, id: \.self) { idx in
                                        HStack(spacing: PGSpacing.sm) {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundStyle(.pgTextSecondary)
                                            Text(editedDraft.requirements[idx].title)
                                                .font(.pgBody)
                                                .foregroundStyle(.pgTextPrimary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Actions
                    PGButton("Confirm & Create Case", icon: "checkmark") {
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
            .navigationTitle("Review Plan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
