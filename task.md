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

- [ ] SearchService (full-text + relationship-aware)
- [ ] Asset management views
- [ ] Notification scheduling (UNUserNotificationCenter)
- [ ] Activity timeline auto-recording (refinement)
- [ ] Visual polish & animations
- [ ] Accessibility pass (Dynamic Type, VoiceOver, contrast)

## Phase 4 — Security, Export & TestFlight (Week 9–10)

- [ ] Sign in with Apple
- [ ] Biometric lock (Face ID / Touch ID)
- [ ] Data encryption at rest
- [ ] Data export (JSON bundle + documents)
- [ ] Data deletion (cascade + document cleanup)
- [ ] CloudKit sync toggle
- [ ] TestFlight setup guide
- [ ] App Store privacy labels
- [x] Unit tests (WorkflowEngine, PriorityEngine, ReminderEngine, OnDeviceAITests)
- [ ] UI tests (critical journeys)
