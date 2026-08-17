// MARK: - Shared UI Components
// PersonalGuide
//
// Reusable components matching the design system:
// rounded cards, buttons, status badges, empty states.

import SwiftUI

// MARK: - PGCard

/// Rounded card with subtle shadow — the primary content container.
struct PGCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(PGSpacing.md)
            .background(Color.pgCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: PGRadius.card))
            .pgCardShadow()
    }
}

// MARK: - PGButton

/// Primary action button with the deep green brand color.
struct PGButton: View {
    let title: String
    let icon: String?
    let style: PGButtonStyle
    let action: () -> Void

    enum PGButtonStyle {
        case primary
        case secondary
        case destructive
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: PGButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: PGSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.pgSubtitle)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: PGConstants.minTapTarget)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: PGRadius.medium)
                        .strokeBorder(Color.pgBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:     return .pgPrimary
        case .secondary:   return .pgCardBackground
        case .destructive: return .pgCritical
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return .pgPrimary
        case .destructive: return .white
        }
    }
}

// MARK: - PGStatusBadge

/// Small pill badge showing case/action status.
struct PGStatusBadge: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    init(status: CaseStatus) {
        self.text = status.displayName
        self.color = Color.statusColor(for: status)
    }

    init(priority: CasePriority) {
        self.text = priority.displayName
        self.color = Color.priorityColor(for: priority)
    }

    var body: some View {
        Text(text)
            .font(.pgSmallLabel)
            .foregroundStyle(color)
            .padding(.horizontal, PGSpacing.xs)
            .padding(.vertical, PGSpacing.xxs)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - PGProgressDots

/// Step progress indicator like ●●○○ (2 of 4 steps).
struct PGProgressDots: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < completed ? Color.pgPositive : Color.pgBorder)
                    .frame(width: 8, height: 8)
            }

            Text("\(completed) of \(total)")
                .font(.pgCaption)
                .foregroundStyle(.pgTextSecondary)
                .padding(.leading, PGSpacing.xxs)
        }
    }
}

// MARK: - PGSectionHeader

/// Consistent section header for Home/Library screens.
struct PGSectionHeader: View {
    let title: String
    let action: (() -> Void)?

    init(_ title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.pgSubtitle)
                .foregroundStyle(.pgTextPrimary)

            Spacer()

            if let action {
                Button("See all", action: action)
                    .font(.pgCaption)
                    .foregroundStyle(.pgTextSecondary)
            }
        }
    }
}

// MARK: - PGEmptyState

/// Placeholder view when a section has no content.
struct PGEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: PGSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.pgTextSecondary.opacity(0.5))

            VStack(spacing: PGSpacing.xs) {
                Text(title)
                    .font(.pgTitle)
                    .foregroundStyle(.pgTextPrimary)

                Text(message)
                    .font(.pgBody)
                    .foregroundStyle(.pgTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PGButton(actionTitle, icon: "plus", style: .secondary, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(PGSpacing.xxl)
    }
}

// MARK: - PGDivider

/// Subtle divider matching the design system.
struct PGDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.pgBorder)
            .frame(height: 1)
    }
}

// MARK: - Deadline Label

/// Shows days remaining with appropriate urgency coloring.
struct DeadlineLabel: View {
    let deadline: Date

    var body: some View {
        let days = Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 0

        HStack(spacing: PGSpacing.xxs) {
            Image(systemName: "clock")
                .font(.pgCaption)
            Text(text(for: days))
                .font(.pgCaption)
        }
        .foregroundStyle(color(for: days))
    }

    private func text(for days: Int) -> String {
        if days < 0 { return "\(abs(days))d overdue" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "\(days) days left"
    }

    private func color(for days: Int) -> Color {
        if days < 0 { return .pgCritical }
        if days <= 3 { return .pgCritical }
        if days <= 7 { return .pgWarning }
        return .pgTextSecondary
    }
}
