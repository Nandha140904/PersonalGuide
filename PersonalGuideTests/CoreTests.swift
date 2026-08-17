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
        XCTAssertFalse(valid.contains(.completed)) // Can't skip to completed from active
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
        XCTAssertEqual(score, 50) // Overdue = max
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
        // Should generate reminders at 30, 14, 7, 3, 1 days before
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
        // Only 3-day and 1-day reminders should be in the future
        XCTAssertEqual(reminders.count, 2)
    }
}
