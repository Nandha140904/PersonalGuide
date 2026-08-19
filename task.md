# Personal Guide — Build Tasks

## Phase 0 — Foundation (Week 1–2)

- [x] Project structure + setup guide
- [x] Enums (CaseStatus, CasePriority, CaseType, ActionStatus, ActionType, RequirementStatus, DocumentType)
- [x] Design System (colors, typography, spacing, components)
- [x] SwiftData Models (PGCase, CaseAction, CaseRequirement, PGDocument, Asset, Person, Reminder, ActivityEvent)
- [x] App entry point (PersonalGuideApp.swift, ModelContainer)
- [x] WorkflowEngine (deterministic state machine)
- [x] PriorityEngine (deterministic scoring)
- [x] ReminderEngine (deterministic schedule)
- [x] CaseService (CRUD + workflow transitions)
- [x] ContentView + Tab navigation (Home / Library / You)
- [x] Shared UI components (PGCard, PGButton, PGStatusBadge, PGProgressDots, etc.)
- [x] Extensions (Date, String)

## Phase 1 — Core Cases (Week 3–4)

- [x] HomeView (greeting, active cases, next actions, coming up, capture)
- [x] ActiveCaseCard
- [x] NextActionCard
- [x] ComingUpRow
- [x] CaptureSection (Scan/Import/Add/Tell Guide buttons)
- [x] CaseDetailView (mini workspace)
- [x] CaseProgressBar (●●○○)
- [x] CaseKnownInfoView ("What I know")
- [x] CaseRequirementsView ("What you need")
- [x] CaseActionsView (all steps)
- [x] CaseTimelineView (activity)
- [x] NextStepCard (primary CTA)
- [x] CreateCaseView (three paths)
- [x] TellGuideView (natural language input + keyword detection)
- [x] ManualCaseFormView (structured form)
- [x] CasePreviewView (AI draft confirm)
- [x] LibraryView (search, pill filters, case rows)
- [x] YouView (privacy, storage, export, delete, settings)

## Phase 2 — Capture & AI (Week 5–7)

- [x] ScanDocumentView (VisionKit)
- [x] DocumentService (upload, store, process)
- [x] AIProvider protocol
- [x] GeminiProvider
- [x] OpenAIProvider
- [x] OnDeviceProvider (Apple Vision + NL)
- [x] AIService orchestrator
- [x] Classifier
- [x] Extractor
- [x] CasePlanner
- [x] Summarizer
- [x] ConversationalInterpreter
- [x] ConfidenceSystem
- [x] Document processing pipeline

## Phase 3 — Polish & Intelligence (Week 7–9)

- [x] SearchService (full-text + relationship-aware)
- [x] Asset management views (AssetsListView, AssetDetailView, CreateAssetView, AssetCard)
- [x] Notification scheduling (UNUserNotificationCenter + NotificationManager)
- [x] Activity timeline auto-recording (refinement)
- [x] Visual polish & micro-animations
- [x] Accessibility pass (Dynamic Type, VoiceOver, contrast)

## Phase 4 — Security, Export & Store Submission (Week 9–10)

- [x] Biometric lock (Face ID / Touch ID via LocalAuthentication)
- [x] Data encryption at rest & local sandbox persistence
- [x] Data export (JSON backup archive + ShareLink)
- [x] Data erasure (secure cascade delete + sandbox folder purge)
- [x] Unit tests (WorkflowEngine, PriorityEngine, ReminderEngine, OnDeviceAITests, SearchServiceTests, AssetTests, DataExportServiceTests)
- [x] Apple Privacy Manifest (PrivacyInfo.xcprivacy with 0-tracking declaration)
- [x] GitHub Actions CI/CD Pipeline (macOS-15 runner, automated testing & TestFlight upload)
- [x] App icon — 1024×1024 shield + compass design in Assets.xcassets/AppIcon.appiconset
- [x] Onboarding — 3-slide first-run experience with notification permission request (OnboardingView.swift)
- [x] Notification permission — UNUserNotificationCenter.requestAuthorization() on last onboarding slide
- [x] NSUserNotificationsUsageDescription added to Info.plist
- [x] App Store Connect metadata — description, keywords, categories, screenshots guide (APP_STORE_METADATA.txt)
- [x] TestFlight signing guide — step-by-step GitHub Secrets setup (GITHUB_ACTIONS_GUIDE.txt)
