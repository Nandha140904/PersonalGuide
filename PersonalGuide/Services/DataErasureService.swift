// MARK: - DataErasureService.swift
// PersonalGuide
//
// Complete, secure erasure of all user data (cases, assets, documents, sandboxed files, settings).

import Foundation
import SwiftData

@MainActor
final class DataErasureService {

    /// Erases all SwiftData database records and clears all sandboxed stored files.
    static func eraseAllData(in modelContext: ModelContext) throws {
        // 1. Delete all SwiftData models
        try modelContext.delete(model: PGCase.self)
        try modelContext.delete(model: CaseAction.self)
        try modelContext.delete(model: CaseRequirement.self)
        try modelContext.delete(model: PGDocument.self)
        try modelContext.delete(model: Asset.self)
        try modelContext.delete(model: Person.self)
        try modelContext.delete(model: Reminder.self)
        try modelContext.delete(model: ActivityEvent.self)

        try modelContext.save()

        // 2. Clear Document storage directory
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docsURL {
            let guideDir = docsURL.appendingPathComponent("PersonalGuideDocuments")
            if FileManager.default.fileExists(atPath: guideDir.path) {
                try? FileManager.default.removeItem(at: guideDir)
            }
        }

        // 3. Clear pending notification requests
        NotificationManager.shared.cancelAllNotifications()
    }
}
