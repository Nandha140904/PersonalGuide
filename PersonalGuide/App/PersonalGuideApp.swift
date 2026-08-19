// MARK: - PersonalGuideApp.swift
// PersonalGuide
//
// @main entry point. Configures SwiftData ModelContainer with all models,
// injects shared services into the environment.

import SwiftUI
import SwiftData

@main
struct PersonalGuideApp: App {

    // MARK: - First-launch onboarding

    @AppStorage("PG_ONBOARDING_COMPLETE") private var isOnboardingComplete: Bool = false

    // MARK: - Services (shared across the app)

    @State private var caseService = CaseService()
    @State private var documentService = DocumentService()
    @State private var aiService = AIService()
    @State private var searchService = SearchService()
    @State private var notificationManager = NotificationManager.shared
    @State private var authService = BiometricAuthService.shared

    // MARK: - SwiftData Container

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PGCase.self,
            CaseAction.self,
            CaseRequirement.self,
            PGDocument.self,
            Asset.self,
            Person.self,
            Reminder.self,
            ActivityEvent.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete {
                ContentView()
                    .environment(caseService)
                    .environment(documentService)
                    .environment(aiService)
                    .environment(searchService)
                    .environment(notificationManager)
                    .environment(authService)
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
