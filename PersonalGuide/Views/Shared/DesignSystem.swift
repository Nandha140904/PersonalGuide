// MARK: - DesignSystem.swift
// PersonalGuide
//
// Apple-grade design system: colors, typography, spacing, corner radii, shadows.
// Strict adherence to HIG, WCAG AA contrast, dynamic type ready.
// Minimal, high-density, text-first — NOT toy-like.

import SwiftUI

// MARK: - Colors

extension Color {

    // Primary & Accent
    static let pgPrimary = Color(hex: "0A84FF")          // Apple System Blue (dark mode safe)
    static let pgAccent = Color(hex: "5E5CE6")           // Indigo accent

    // Semantic / Status
    static let pgPositive = Color(hex: "30D158")         // Green — complete, verified
    static let pgWarning = Color(hex: "FF9F0A")          // Orange — upcoming, action needed
    static let pgCritical = Color(hex: "FF453A")         // Red — overdue, urgent, blocked

    // Backgrounds (adaptive)
    static let pgBackground = Color(UIColor.systemBackground)
    static let pgCardBackground = Color(UIColor.secondarySystemBackground)
    static let pgSurface = Color(UIColor.tertiarySystemBackground)

    // Text
    static let pgTextPrimary = Color(UIColor.label)
    static let pgTextSecondary = Color(UIColor.secondaryLabel)
    static let pgTextTertiary = Color(UIColor.tertiaryLabel)

    // Borders & Dividers
    static let pgBorder = Color(UIColor.separator)
    static let pgDivider = Color(UIColor.opaqueSeparator)

    // Case-type subtle tint colors
    static func caseTypeColor(_ type: CaseType) -> Color {
        switch type {
        case .purchaseReturn:
            return Color(hex: "FF9F0A")  // Orange
        case .subscriptionBill:
            return Color(hex: "BF5AF2")  // Purple
        case .documentRenewal:
            return Color(hex: "0A84FF")  // Blue
        case .insuranceWarranty:
            return Color(hex: "30D158")  // Green
        case .genericLifeAdmin:
            return Color(hex: "64D2FF")  // Cyan
        }
    }

    static func caseTypeColor(for type: CaseType) -> Color {
        caseTypeColor(type)
    }

    // Priority badge colors
    static func priorityColor(_ priority: CasePriority) -> Color {
        switch priority {
        case .urgent:
            return .pgCritical
        case .high:
            return .pgWarning
        case .normal:
            return .pgPrimary
        case .low:
            return .pgTextSecondary
        }
    }

    static func priorityColor(for priority: CasePriority) -> Color {
        priorityColor(priority)
    }

    // Status badge colors
    static func statusColor(_ status: CaseStatus) -> Color {
        switch status {
        case .draft:
            return .pgTextSecondary
        case .active, .inProgress:
            return .pgPrimary
        case .needsInformation:
            return .pgWarning
        case .readyForAction:
            return Color(hex: "30D158")
        case .waiting:
            return Color(hex: "BF5AF2")
        case .blocked:
            return .pgCritical
        case .completed:
            return .pgPositive
        case .cancelled, .archived:
            return .pgTextSecondary
        }
    }

    static func statusColor(for status: CaseStatus) -> Color {
        statusColor(status)
    }
}

// MARK: - ShapeStyle Conformance

extension ShapeStyle where Self == Color {
    static var pgPrimary: Color { .pgPrimary }
    static var pgBackground: Color { .pgBackground }
    static var pgCardBackground: Color { .pgCardBackground }
    static var pgPositive: Color { .pgPositive }
    static var pgWarning: Color { .pgWarning }
    static var pgCritical: Color { .pgCritical }
    static var pgTextPrimary: Color { .pgTextPrimary }
    static var pgTextSecondary: Color { .pgTextSecondary }
    static var pgBorder: Color { .pgBorder }
    static var pgSurface: Color { .pgSurface }
    static var pgAccent: Color { .pgAccent }
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

    /// Button text (17pt semibold).
    static let pgButton = Font.system(size: 17, weight: .semibold, design: .default)

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

    /// Elevated shadow for modals and primary cards.
    func pgElevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Animation Standards

extension Animation {
    /// Standard spring for card expansions, step checks, status changes.
    static let pgSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)

    /// Quick fade/color transition.
    static let pgQuick = Animation.easeOut(duration: 0.2)
}

// MARK: - Constants

enum PGConstants {
    static let minTapTarget: CGFloat = 44

    static var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}
