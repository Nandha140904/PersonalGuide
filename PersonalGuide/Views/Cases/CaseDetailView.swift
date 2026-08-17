// MARK: - CaseDetailView.swift
// PersonalGuide
//
// The case "mini workspace" — where the user does their actual work.
// Every case feels like a focused workspace showing:
// - Progress, deadline, what's known, what's needed, next step, documents, timeline.
// The primary button always answers: "What should I do next?"

import SwiftUI
import SwiftData

struct CaseDetailView: View {

    @Bindable var pgCase: PGCase
    @Environment(CaseService.self) private var caseService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showCompleteConfirmation = false
    @State private var showCancelConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PGSpacing.lg) {

                // MARK: - Header
                caseHeader

                // MARK: - Progress
                if progress.total > 0 {
                    progressSection
                }

                // MARK: - Deadline
                if let deadline = pgCase.deadline {
                    deadlineSection(deadline)
                }

                // MARK: - What I Know
                if !pgCase.metadata.isEmpty || !pgCase.descriptionText.isEmpty {
                    knownInfoSection
                }

                // MARK: - What You Need (Requirements)
                if !pgCase.requirements.isEmpty {
                    requirementsSection
                }

                // MARK: - Next Step
                if let nextAction = pgCase.nextAction {
                    nextStepSection(nextAction)
                }

                // MARK: - All Steps
                if !pgCase.actions.isEmpty {
                    allStepsSection
                }

                // MARK: - Documents
                if !pgCase.documents.isEmpty {
                    documentsSection
                }

                // MARK: - Timeline
                if !pgCase.events.isEmpty {
                    timelineSection
                }

                // MARK: - Case Actions
                caseActionsSection
            }
            .padding(.horizontal, PGSpacing.md)
            .padding(.bottom, PGSpacing.xxl)
        }
        .background(Color.pgBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(pgCase.caseType.shortLabel.uppercased())
                    .font(.pgSmallLabel)
                    .tracking(2)
                    .foregroundStyle(.pgTextSecondary)
            }
        }
        .confirmationDialog(
            "Complete this case?",
            isPresented: $showCompleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Mark as completed") {
                try? caseService.completeCase(pgCase, in: modelContext)
            }
        } message: {
            Text("This will mark \"\(pgCase.title)\" as done and archive it.")
        }
        .confirmationDialog(
            "Cancel this case?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel case", role: .destructive) {
                try? caseService.cancelCase(pgCase, in: modelContext)
                dismiss()
            }
        } message: {
            Text("This will cancel \"\(pgCase.title)\". You can reactivate it later.")
        }
    }

    // MARK: - Computed

    private var progress: (completed: Int, total: Int) {
        pgCase.completionProgress
    }

    // MARK: - Sections

    private var caseHeader: some View {
        VStack(alignment: .leading, spacing: PGSpacing.xs) {
            HStack {
                PGStatusBadge(status: pgCase.status)
                if pgCase.priority >= .high {
                    PGStatusBadge(priority: pgCase.priority)
                }
                Spacer()
            }

            Text(pgCase.title)
                .font(.pgHeading)
                .foregroundStyle(.pgTextPrimary)

            if !pgCase.descriptionText.isEmpty {
                Text(pgCase.descriptionText)
                    .font(.pgBody)
                    .foregroundStyle(.pgTextSecondary)
            }
        }
        .padding(.top, PGSpacing.sm)
    }

    private var progressSection: some View {
        PGCard {
            HStack {
                PGProgressDots(completed: progress.completed, total: progress.total)
                Spacer()
                Text("\(progress.completed) of \(progress.total) steps")
                    .font(.pgCaption)
                    .foregroundStyle(.pgTextSecondary)
            }
        }
    }

    private func deadlineSection(_ deadline: Date) -> some View {
        PGCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEADLINE")
                        .font(.pgSmallLabel)
                        .foregroundStyle(.pgTextSecondary)
                        .tracking(1)
                    Text(deadline, format: .dateTime.day().month(.wide).year())
                        .font(.pgTitle)
                        .foregroundStyle(.pgTextPrimary)
                }
                Spacer()
                DeadlineLabel(deadline: deadline)
            }
        }
    }

    private var knownInfoSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("What I know")

            PGCard {
                VStack(alignment: .leading, spacing: PGSpacing.sm) {
                    if !pgCase.descriptionText.isEmpty {
                        Text(pgCase.descriptionText)
                            .font(.pgBody)
                            .foregroundStyle(.pgTextPrimary)
                    }

                    ForEach(Array(pgCase.metadata.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack {
                            Text(key.capitalized.replacingOccurrences(of: "_", with: " "))
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                            Spacer()
                            Text(value)
                                .font(.pgBody)
                                .foregroundStyle(.pgTextPrimary)
                        }
                    }
                }
            }
        }
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("What you need")

            PGCard {
                VStack(alignment: .leading, spacing: PGSpacing.sm) {
                    ForEach(pgCase.requirements) { req in
                        HStack(spacing: PGSpacing.sm) {
                            Image(systemName: req.requirementStatus.iconName)
                                .foregroundStyle(
                                    req.requirementStatus.isSatisfied
                                        ? Color.pgPositive
                                        : Color.pgWarning
                                )
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(req.title)
                                    .font(.pgBody)
                                    .foregroundStyle(.pgTextPrimary)
                                    .strikethrough(req.requirementStatus.isSatisfied)

                                if !req.descriptionText.isEmpty {
                                    Text(req.descriptionText)
                                        .font(.pgCaption)
                                        .foregroundStyle(.pgTextSecondary)
                                }
                            }

                            Spacer()

                            Text(req.requirementStatus.displayName)
                                .font(.pgSmallLabel)
                                .foregroundStyle(.pgTextSecondary)
                        }

                        if req.id != pgCase.requirements.last?.id {
                            PGDivider()
                        }
                    }
                }
            }
        }
    }

    private func nextStepSection(_ action: CaseAction) -> some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("Next step")

            PGCard {
                VStack(alignment: .leading, spacing: PGSpacing.sm) {
                    HStack {
                        Image(systemName: action.actionType.iconName)
                            .foregroundStyle(.pgPrimary)
                        Text(action.title)
                            .font(.pgSubtitle)
                            .foregroundStyle(.pgTextPrimary)
                    }

                    if !action.descriptionText.isEmpty {
                        Text(action.descriptionText)
                            .font(.pgBody)
                            .foregroundStyle(.pgTextSecondary)
                    }

                    if let url = action.externalURL {
                        Link(destination: URL(string: url) ?? URL(string: "about:blank")!) {
                            HStack {
                                Image(systemName: "arrow.up.forward.square")
                                Text("Open link")
                            }
                            .font(.pgCaption)
                            .foregroundStyle(.pgPrimary)
                        }
                    }

                    PGButton("Continue", icon: "arrow.forward") {
                        try? caseService.completeAction(action, in: modelContext)
                    }
                }
            }
        }
    }

    private var allStepsSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("All steps")

            PGCard {
                VStack(alignment: .leading, spacing: PGSpacing.xs) {
                    ForEach(pgCase.sortedActions) { action in
                        HStack(spacing: PGSpacing.sm) {
                            Image(systemName: action.status.iconName)
                                .foregroundStyle(
                                    action.status.isDone
                                        ? Color.pgPositive
                                        : action.status.isActionable
                                            ? Color.pgPrimary
                                            : Color.pgTextSecondary
                                )
                                .frame(width: 24)

                            Text(action.title)
                                .font(.pgBody)
                                .foregroundStyle(
                                    action.status.isDone
                                        ? .pgTextSecondary
                                        : .pgTextPrimary
                                )
                                .strikethrough(action.status.isDone)

                            Spacer()

                            if action.status.isActionable {
                                Button("Do it") {
                                    try? caseService.completeAction(action, in: modelContext)
                                }
                                .font(.pgSmallLabel)
                                .foregroundStyle(.pgPrimary)
                            }
                        }
                        .padding(.vertical, PGSpacing.xxs)
                    }
                }
            }
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("Documents")

            ForEach(pgCase.documents) { doc in
                PGCard {
                    HStack(spacing: PGSpacing.sm) {
                        Image(systemName: doc.documentType.iconName)
                            .foregroundStyle(.pgPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.fileName)
                                .font(.pgBody)
                                .foregroundStyle(.pgTextPrimary)
                            Text(doc.documentType.displayName)
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.pgTextSecondary)
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("Activity")

            PGCard {
                VStack(alignment: .leading, spacing: PGSpacing.sm) {
                    ForEach(pgCase.events.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5)) { event in
                        HStack(spacing: PGSpacing.sm) {
                            Image(systemName: event.eventType.iconName)
                                .font(.pgCaption)
                                .foregroundStyle(.pgTextSecondary)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.pgCaption)
                                    .foregroundStyle(.pgTextPrimary)
                                Text(event.timestamp, format: .dateTime.day().month().hour().minute())
                                    .font(.pgSmallLabel)
                                    .foregroundStyle(.pgTextSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var caseActionsSection: some View {
        VStack(spacing: PGSpacing.sm) {
            if pgCase.status.isOpen && pgCase.status != .completed {
                PGButton("Complete case", icon: "checkmark.seal") {
                    showCompleteConfirmation = true
                }

                PGButton("Cancel case", icon: "xmark", style: .destructive) {
                    showCancelConfirmation = true
                }
            }

            if pgCase.status == .completed {
                PGButton("Reopen case", icon: "arrow.counterclockwise", style: .secondary) {
                    try? caseService.workflowEngine.transition(
                        pgCase, to: .active, in: modelContext
                    )
                }
            }
        }
        .padding(.top, PGSpacing.md)
    }
}

#Preview {
    NavigationStack {
        CaseDetailView(
            pgCase: PGCase(
                title: "Renew Car Insurance",
                descriptionText: "HDFC Ergo car insurance policy renewal",
                caseType: .insuranceWarranty,
                source: .naturalLanguage,
                status: .active,
                priority: .high,
                deadline: Calendar.current.date(byAdding: .day, value: 7, to: .now)
            )
        )
    }
    .modelContainer(for: PGCase.self, inMemory: true)
    .environment(CaseService())
}
