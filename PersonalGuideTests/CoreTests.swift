import XCTest
@testable import PersonalGuide

final class WorkflowEngineTests: XCTestCase {

    var engine: WorkflowEngine!

    override func setUp() {
        super.setUp()
        engine = WorkflowEngine()
    }

    // MARK: - Valid Transitions

    func testDraftToActive() {
        XCTAssertTrue(engine.canTransition(from: .draft, to: .active))
    }

    func testActiveToNeedsInformation() {
        XCTAssertTrue(engine.canTransition(from: .active, to: .needsInformation))
    }

    func testActiveToReadyForAction() {
        XCTAssertTrue(engine.canTransition(from: .active, to: .readyForAction))
    }

    func testInProgressToCompleted() {
        XCTAssertTrue(engine.canTransition(from: .inProgress, to: .completed))
    }

    func testCompletedToArchived() {
        XCTAssertTrue(engine.canTransition(from: .completed, to: .archived))
    }

    func testCompletedToActiveReopening() {
        XCTAssertTrue(engine.canTransition(from: .completed, to: .active))
    }

    func testCancelledToActiveReactivation() {
        XCTAssertTrue(engine.canTransition(from: .cancelled, to: .active))
    }

    // MARK: - Invalid Transitions

    func testDraftToCompletedNotAllowed() {
        XCTAssertFalse(engine.canTransition(from: .draft, to: .completed))
    }

    func testCompletedToDraftNotAllowed() {
        XCTAssertFalse(engine.canTransition(from: .completed, to: .draft))
    }

    func testSameStatusNotAllowed() {
        XCTAssertFalse(engine.canTransition(from: .active, to: .active))
    }

    func testArchivedToCompletedNotAllowed() {
        XCTAssertFalse(engine.canTransition(from: .archived, to: .completed))
    }

    // MARK: - Valid Next Statuses

    func testValidNextFromDraft() {
        let valid = engine.validNextStatuses(from: .draft)
        XCTAssertTrue(valid.contains(.active))
        XCTAssertTrue(valid.contains(.cancelled))
        XCTAssertEqual(valid.count, 2)
    }

    func testValidNextFromActive() {
        let valid = engine.validNextStatuses(from: .active)
        XCTAssertTrue(valid.contains(.needsInformation))
        XCTAssertTrue(valid.contains(.readyForAction))
        XCTAssertTrue(valid.contains(.inProgress))
        XCTAssertFalse(valid.contains(.completed))
    }
}

final class PriorityEngineTests: XCTestCase {

    var engine: PriorityEngine!

    override func setUp() {
        super.setUp()
        engine = PriorityEngine()
    }

    func testOverdueCaseGetsMaxDeadlineScore() {
        let pgCase = PGCase(
            title: "Test",
            caseType: .genericLifeAdmin,
            deadline: Calendar.current.date(byAdding: .day, value: -1, to: .now)
        )
        let score = engine.deadlineScore(for: pgCase)
        XCTAssertEqual(score, 50)
    }

    func testNearDeadlineScoresHigherThanFarDeadline() {
        let nearCase = PGCase(
            title: "Near",
            deadline: Calendar.current.date(byAdding: .day, value: 3, to: .now)
        )
        let farCase = PGCase(
            title: "Far",
            deadline: Calendar.current.date(byAdding: .day, value: 30, to: .now)
        )
        XCTAssertGreaterThan(
            engine.deadlineScore(for: nearCase),
            engine.deadlineScore(for: farCase)
        )
    }

    func testNoDeadlineGetsBaselineScore() {
        let pgCase = PGCase(title: "No deadline")
        let score = engine.deadlineScore(for: pgCase)
        XCTAssertEqual(score, 5)
    }

    func testInsuranceCaseScoresHigherConsequence() {
        let insurance = PGCase(title: "Insurance", caseType: .insuranceWarranty)
        let generic = PGCase(title: "Generic", caseType: .genericLifeAdmin)
        XCTAssertGreaterThan(
            engine.consequenceScore(for: insurance),
            engine.consequenceScore(for: generic)
        )
    }

    func testHigherUserPriorityScoresHigher() {
        let urgent = PGCase(title: "Urgent", priority: .urgent)
        let low = PGCase(title: "Low", priority: .low)
        XCTAssertGreaterThan(
            engine.userPriorityScore(for: urgent),
            engine.userPriorityScore(for: low)
        )
    }
}

final class ReminderEngineTests: XCTestCase {

    var engine: ReminderEngine!

    override func setUp() {
        super.setUp()
        engine = ReminderEngine()
    }

    func testGeneratesRemindersForFutureDeadline() {
        let pgCase = PGCase(
            title: "Test",
            deadline: Calendar.current.date(byAdding: .day, value: 60, to: .now)
        )
        let reminders = engine.generateReminders(for: pgCase)
        XCTAssertEqual(reminders.count, 5)
    }

    func testNoRemindersForPastDeadline() {
        let pgCase = PGCase(
            title: "Test",
            deadline: Calendar.current.date(byAdding: .day, value: -5, to: .now)
        )
        let reminders = engine.generateReminders(for: pgCase)
        XCTAssertTrue(reminders.isEmpty)
    }

    func testNoRemindersWithoutDeadline() {
        let pgCase = PGCase(title: "Test")
        let reminders = engine.generateReminders(for: pgCase)
        XCTAssertTrue(reminders.isEmpty)
    }

    func testNearDeadlineGeneratesFewerReminders() {
        let pgCase = PGCase(
            title: "Test",
            deadline: Calendar.current.date(byAdding: .day, value: 5, to: .now)
        )
        let reminders = engine.generateReminders(for: pgCase)
        XCTAssertEqual(reminders.count, 2)
    }
}

final class OnDeviceAITests: XCTestCase {

    var provider: OnDeviceProvider!

    override func setUp() {
        super.setUp()
        provider = OnDeviceProvider()
    }

    func testClassifyReturnIntent() async throws {
        let result = try await provider.classify(text: "I want to return the defective shoes I bought on Amazon")
        XCTAssertEqual(result.caseType, .purchaseReturn)
        XCTAssertEqual(result.documentType, .receipt)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
    }

    func testClassifyInsuranceIntent() async throws {
        let result = try await provider.classify(text: "My car insurance policy renewal is due next month with Geico")
        XCTAssertEqual(result.caseType, .insuranceWarranty)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
    }

    func testPlanCaseGeneratesOrderedActions() async throws {
        let plan = try await provider.planCase(intent: "Return headphones bought on Amazon order #12345", extractedInfo: nil)
        XCTAssertEqual(plan.caseType, .purchaseReturn)
        XCTAssertFalse(plan.actions.isEmpty)
        XCTAssertFalse(plan.requirements.isEmpty)
        XCTAssertNotNil(plan.suggestedDeadline)
    }
}

final class SearchServiceTests: XCTestCase {

    @MainActor
    func testSearchMatchesCaseTitleAndCategory() {
        let searchService = SearchService()
        let case1 = PGCase(title: "Renew Geico Insurance Policy", caseType: .insuranceWarranty)
        case1.category = "Geico"
        let case2 = PGCase(title: "Return Amazon Order", caseType: .purchaseReturn)

        let results = searchService.search(
            query: "Geico",
            allCases: [case1, case2],
            allDocuments: [],
            allAssets: []
        )

        XCTAssertEqual(results.cases.count, 1)
        XCTAssertEqual(results.cases.first?.title, "Renew Geico Insurance Policy")
    }

    @MainActor
    func testSearchMatchesDocumentOCRText() {
        let searchService = SearchService()
        let doc1 = PGDocument(fileName: "Policy.pdf", mimeType: "application/pdf", storagePath: "docs/policy.pdf")
        doc1.extractedText = "Policy Number POL-987654. Effective date January 2026."

        let results = searchService.search(
            query: "POL-987654",
            allCases: [],
            allDocuments: [doc1],
            allAssets: []
        )

        XCTAssertEqual(results.documents.count, 1)
        XCTAssertEqual(results.documents.first?.fileName, "Policy.pdf")
    }

    @MainActor
    func testSearchMatchesAssetSerialNumber() {
        let searchService = SearchService()
        let asset1 = Asset(name: "MacBook Pro", assetType: .laptop)
        asset1.serialNumber = "C02XYZ1234"

        let results = searchService.search(
            query: "C02XYZ",
            allCases: [],
            allDocuments: [],
            allAssets: [asset1]
        )

        XCTAssertEqual(results.assets.count, 1)
        XCTAssertEqual(results.assets.first?.name, "MacBook Pro")
    }
}

final class AssetTests: XCTestCase {

    func testAssetWarrantyStatus() {
        let asset = Asset(
            name: "iPhone 14 Pro",
            assetType: .phone,
            warrantyEndDate: Calendar.current.date(byAdding: .month, value: 6, to: .now)
        )
        XCTAssertTrue(asset.isUnderWarranty)

        let oldAsset = Asset(
            name: "Old Laptop",
            assetType: .laptop,
            warrantyEndDate: Calendar.current.date(byAdding: .year, value: -2, to: .now)
        )
        XCTAssertFalse(oldAsset.isUnderWarranty)
    }

    func testAssetMetadataJSON() {
        let asset = Asset(name: "Tesla Model Y", assetType: .vehicle)
        asset.manufacturer = "Tesla"
        asset.modelNumber = "Model Y Long Range"
        asset.serialNumber = "5YJSA1E28HF123456"

        XCTAssertEqual(asset.manufacturer, "Tesla")
        XCTAssertEqual(asset.modelNumber, "Model Y Long Range")
        XCTAssertEqual(asset.serialNumber, "5YJSA1E28HF123456")
        XCTAssertNotNil(asset.metadataJSON)
    }
}
