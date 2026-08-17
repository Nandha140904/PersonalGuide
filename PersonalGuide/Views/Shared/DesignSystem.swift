// MARK: - DesignSystem.swift
// PersonalGuide
//
// Premium design tokens matching the spec's visual direction:
// calm, premium, minimal iPhone-first UI with deep forest green,
// warm cream background, restrained status colors, large typography.

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Deep forest green — primary brand color.
    static let pgPrimary = Color(hex: "1B4332")

    /// Warm cream/off-white — default background.
    static let pgBackground = Color(hex: "FAF8F0")

    /// Pure white — card surfaces.
    static let pgCardBackground = Color.white

    /// Muted green — positive/completed status.
    static let pgPositive = Color(hex: "40916C")

    /// Muted peach/orange — warning/approaching status.
    static let pgWarning = Color(hex: "E8A87C")

    /// Restrained red — critical/overdue status.
    static let pgCritical = Color(hex: "BC4749")

    /// Deep green/near-black — primary text.
    static let pgTextPrimary = Color(hex: "1B4332")

    /// Muted green-grey — secondary text.
    static let pgTextSecondary = Color(hex: "6B7A6F")

    /// Light sage — subtle borders and dividers.
    static let pgBorder = Color(hex: "D8E2DC")

    /// Very light green tint — subtle surface highlight.
    static let pgSurface = Color(hex: "F0F5F1")

    /// Accent peach for interactive highlights.
    static let pgAccent = Color(hex: "E8A87C")

    /// Color for specific case/priority status contexts.
    static func statusColor(for status: CaseStatus) -> Color {
        switch status {
        case .draft:            return .pgTextSecondary
        case .active:           return .pgPrimary
        case .needsInformation: return .pgWarning
        case .readyForAction:   return .pgPositive
        case .inProgress:       return .pgPrimary
        case .waiting:          return .pgTextSecondary
        case .blocked:          return .pgCritical
        case .completed:        return .pgPositive
        case .cancelled:        return .pgTextSecondary
        case .archived:         return .pgTextSecondary
        }
    }

    static func priorityColor(for priority: CasePriority) -> Color {
        switch priority {
        case .low:      return .pgTextSecondary
        case .normal:   return .pgPrimary
        case .high:     return .pgWarning
        case .urgent:   return .pgCritical
        case .critical: return .pgCritical
        }
    }
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

extension Font {
    /// Hero heading — greeting, page titles (34pt SF Pro Display).
    static let pgHero = Font.system(size: 34, weight: .bold, design: .default)

    /// Large heading — section titles (28pt).
    static let pgHeading = Font.system(size: 28, weight: .bold, design: .default)

    /// Card title (20pt semibold).
    static let pgTitle = Font.system(size: 20, weight: .semibold, design: .default)

    /// Subtitle / label (17pt medium).
    static let pgSubtitle = Font.system(size: 17, weight: .medium, design: .default)

    /// Body text (15pt regular).
    static let pgBody = Font.system(size: 15, weight: .regular, design: .default)

    /// Caption / supporting text (13pt).
    static let pgCaption = Font.system(size: 13, weight: .regular, design: .default)

    /// Small label (11pt medium) — badges, counts.
    static let pgSmallLabel = Font.system(size: 11, weight: .medium, design: .default)

    /// Monospaced for values/numbers (15pt).
    static let pgMono = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// MARK: - Spacing

enum PGSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum PGRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let card: CGFloat = 16
    static let large: CGFloat = 20
    static let pill: CGFloat = 100
}

// MARK: - Shadows

extension View {
    /// Subtle card shadow matching the premium, minimal aesthetic.
    func pgCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    /// Elevated shadow for modals and floating elements.
    func pgElevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Animation

extension Animation {
    /// Standard spring animation for transitions.
    static let pgSpring = Animation.spring(response: 0.35, dampingFraction: 0.85)

    /// Quick animation for micro-interactions.
    static let pgQuick = Animation.easeOut(duration: 0.2)
}

// MARK: - Constants

enum PGConstants {
    /// Minimum tap target size per Apple HIG and spec (44pt).
    static let minTapTarget: CGFloat = 44

    /// Maximum content width for iPad/larger screens.
    static let maxContentWidth: CGFloat = 500

    /// Home greeting messages.
    static let greetings: [String] = [
        "Keep life moving.",
        "Let's get things done.",
        "Your life admin, simplified.",
    ]

    /// Time-aware greeting.
    static var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Hello"
        }
    }
}
