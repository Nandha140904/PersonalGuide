// MARK: - Date+Extensions.swift
// PersonalGuide

import Foundation

extension Date {
    /// Relative description like "3 days ago", "in 5 days", "today".
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    /// Short date string (e.g., "23 Aug").
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    /// Full date string (e.g., "23 August 2026").
    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }

    /// Days from now (positive = future, negative = past).
    var daysFromNow: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: self)).day ?? 0
    }
}

// MARK: - String+Extensions.swift

extension String {
    /// Truncate to a maximum length with ellipsis.
    func truncated(to maxLength: Int) -> String {
        if count <= maxLength { return self }
        return String(prefix(maxLength - 1)) + "…"
    }

    /// Clean whitespace and newlines from user input.
    var cleanedInput: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
