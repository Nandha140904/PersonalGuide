// MARK: - HomeView.swift
// PersonalGuide
//
// Purpose: "What needs my attention and what should I do next?"
//
// Sections:
// 1. Greeting — "Keep life moving."
// 2. Active cases — prioritized by actionability and urgency
// 3. Recommended next actions — the actual work to perform
// 4. Coming up — future cases not yet actionable
// 5. Capture — Scan / Import / Add / Tell Guide
//
// Do NOT make reminders the hero of Home.

import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(CaseService.self) private var caseService
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<PGCase> { $0.statusRaw != "ARCHIVED" && $0.statusRaw != "CANCELLED" },
        sort: \PGCase.updatedAt,
        order: .reverse
    )
    private var allCases: [PGCase]

    @State private var showCreateCase = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PGSpacing.lg) {

                    // MARK: - Greeting
                    greetingSection

                    // MARK: - Quick Status
                    quickStatusSection

                    // MARK: - Needs Attention
                    if !needsAttentionCases.isEmpty {
                        activeSection
                    }

                    // MARK: - Next Actions
                    if !nextActions.isEmpty {
                        nextActionsSection
                    }

                    // MARK: - Coming Up
                    if !comingUpCases.isEmpty {
                        comingUpSection
                    }

                    // MARK: - Capture
                    captureSection

                    // Empty State
                    if allCases.isEmpty {
                        PGEmptyState(
                            icon: "compass.drawing",
                            title: "Your guide is ready",
                            message: "Capture something happening in your life and let Personal Guide help you get it done.",
                            actionTitle: "Get started",
                            action: { showCreateCase = true }
                        )
                    }
                }
                .padding(.horizontal, PGSpacing.md)
                .padding(.bottom, PGSpacing.xxl)
            }
            .background(Color.pgBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PERSONAL GUIDE")
                        .font(.pgSmallLabel)
                        .tracking(2)
                        .foregroundStyle(.pgTextSecondary)
                }
            }
            .sheet(isPresented: $showCreateCase) {
                CreateCaseView()
            }
        }
    }

    // MARK: - Computed

    private var needsAttentionCases: [PGCase] {
        caseService.casesNeedingAttention(allCases)
    }

    private var activeCases: [PGCase] {
        caseService.prioritizedCases(allCases)
    }

    private var comingUpCases: [PGCase] {
        caseService.upcomingCases(allCases)
    }

    private var nextActions: [(pgCase: PGCase, action: CaseAction)] {
        activeCases.compactMap { pgCase in
            guard let action = pgCase.nextAction else { return nil }
            return (pgCase, action)
        }
        .prefix(3)
        .map { $0 }
    }

    private var completedCount: Int {
        allCases.filter { $0.status == .completed }.count
    }

    // MARK: - Sections

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.xs) {
            Text(PGConstants.timeGreeting)
                .font(.pgHero)
                .foregroundStyle(.pgTextPrimary)

            Text("Keep life moving.")
                .font(.pgBody)
                .foregroundStyle(.pgTextSecondary)

            if !allCases.isEmpty {
                Text("Here's what needs your attention today.")
                    .font(.pgCaption)
                    .foregroundStyle(.pgTextSecondary)
            }
        }
        .padding(.top, PGSpacing.md)
    }

    private var quickStatusSection: some View {
        HStack(spacing: PGSpacing.sm) {
            QuickStatPill(
                label: "Active",
                count: allCases.filter { $0.status.isActionable }.count,
                color: .pgPrimary
            )
            QuickStatPill(
                label: "Waiting",
                count: allCases.filter { $0.status == .waiting }.count,
                color: .pgTextSecondary
            )
            QuickStatPill(
                label: "Needs info",
                count: allCases.filter { $0.status == .needsInformation }.count,
                color: .pgWarning
            )
            QuickStatPill(
                label: "Done",
                count: completedCount,
                color: .pgPositive
            )
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("Needs attention")

            ForEach(needsAttentionCases) { pgCase in
                NavigationLink(value: pgCase) {
                    ActiveCaseCard(pgCase: pgCase)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: PGCase.self) { pgCase in
            CaseDetailView(pgCase: pgCase)
        }
    }

    private var nextActionsSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("Recommended next")

            ForEach(nextActions, id: \.pgCase.id) { item in
                NavigationLink(value: item.pgCase) {
                    NextActionCard(pgCase: item.pgCase, action: item.action)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var comingUpSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("Coming up")

            ForEach(comingUpCases) { pgCase in
                NavigationLink(value: pgCase) {
                    ComingUpRow(pgCase: pgCase)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var captureSection: some View {
        VStack(alignment: .leading, spacing: PGSpacing.sm) {
            PGSectionHeader("Capture something")

            HStack(spacing: PGSpacing.sm) {
                CaptureButton(icon: "doc.viewfinder", label: "Scan") {
                    // Phase 2: Document scanning
                    showCreateCase = true
                }
                CaptureButton(icon: "arrow.down.doc", label: "Import") {
                    showCreateCase = true
                }
                CaptureButton(icon: "plus", label: "Add") {
                    showCreateCase = true
                }
                CaptureButton(icon: "text.bubble", label: "Tell Guide") {
                    showCreateCase = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct QuickStatPill: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.pgSubtitle)
                .foregroundStyle(color)
            Text(label)
                .font(.pgSmallLabel)
                .foregroundStyle(.pgTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PGSpacing.sm)
        .background(Color.pgSurface)
        .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))
    }
}

private struct ActiveCaseCard: View {
    let pgCase: PGCase

    var body: some View {
        PGCard {
            VStack(alignment: .leading, spacing: PGSpacing.sm) {
                HStack {
                    Image(systemName: pgCase.caseType.iconName)
                        .foregroundStyle(.pgPrimary)
                    Text(pgCase.caseType.shortLabel.uppercased())
                        .font(.pgSmallLabel)
                        .foregroundStyle(.pgTextSecondary)
                        .tracking(1)
                    Spacer()
                    PGStatusBadge(status: pgCase.status)
                }

                Text(pgCase.title)
                    .font(.pgTitle)
                    .foregroundStyle(.pgTextPrimary)
                    .lineLimit(2)

                HStack {
                    let progress = pgCase.completionProgress
                    if progress.total > 0 {
                        PGProgressDots(completed: progress.completed, total: progress.total)
                    }

                    Spacer()

                    if let deadline = pgCase.deadline {
                        DeadlineLabel(deadline: deadline)
                    }
                }

                if let nextAction = pgCase.nextAction {
                    HStack(spacing: PGSpacing.xs) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .foregroundStyle(.pgPrimary)
                        Text(nextAction.title)
                            .font(.pgCaption)
                            .foregroundStyle(.pgTextPrimary)
                    }
                    .padding(PGSpacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.pgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: PGRadius.small))
                }
            }
        }
    }
}

private struct NextActionCard: View {
    let pgCase: PGCase
    let action: CaseAction

    var body: some View {
        PGCard {
            HStack(spacing: PGSpacing.sm) {
                Image(systemName: action.actionType.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(.pgPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.pgSurface)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(pgCase.title)
                        .font(.pgCaption)
                        .foregroundStyle(.pgTextSecondary)
                    Text(action.title)
                        .font(.pgSubtitle)
                        .foregroundStyle(.pgTextPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.pgTextSecondary)
            }
        }
    }
}

private struct ComingUpRow: View {
    let pgCase: PGCase

    var body: some View {
        HStack(spacing: PGSpacing.sm) {
            Image(systemName: pgCase.caseType.iconName)
                .foregroundStyle(.pgTextSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(pgCase.title)
                    .font(.pgBody)
                    .foregroundStyle(.pgTextPrimary)
                if let deadline = pgCase.deadline {
                    DeadlineLabel(deadline: deadline)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.pgCaption)
                .foregroundStyle(.pgTextSecondary)
        }
        .padding(.vertical, PGSpacing.xs)
    }
}

private struct CaptureButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: PGSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.pgPrimary)
                Text(label)
                    .font(.pgSmallLabel)
                    .foregroundStyle(.pgTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.pgSurface)
            .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: PGCase.self, inMemory: true)
        .environment(CaseService())
}
