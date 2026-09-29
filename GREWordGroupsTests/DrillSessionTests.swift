import XCTest
@testable import GREWordGroups

final class DrillSessionTests: XCTestCase {
    func testSessionCountsResultsUntilComplete() {
        var session = DrillSession(length: 3)
        session.record(isCorrect: true)
        session.record(isCorrect: false)
        XCTAssertFalse(session.isComplete)

        session.record(isCorrect: true)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.correctCount, 2)
        XCTAssertEqual(session.results, [true, false, true])
    }

    func testCompleteSessionIgnoresExtraResults() {
        var session = DrillSession(length: 1)
        session.record(isCorrect: true)
        session.record(isCorrect: false)
        XCTAssertEqual(session.results, [true])
    }

    func testResetClearsResults() {
        var session = DrillSession(length: 2)
        session.record(isCorrect: true)
        session.reset()
        XCTAssertEqual(session.answeredCount, 0)
        XCTAssertFalse(session.isComplete)
    }

    func testGroupFiltersUseMasteryBands() {
        typealias Filter = GroupsViewModel.Filter
        XCTAssertTrue(Filter.notStarted.matches(mastery: 0))
        XCTAssertFalse(Filter.notStarted.matches(mastery: 0.04))
        XCTAssertTrue(Filter.inProgress.matches(mastery: 0.04))
        XCTAssertTrue(Filter.inProgress.matches(mastery: 0.79))
        XCTAssertFalse(Filter.inProgress.matches(mastery: 0.8))
        XCTAssertTrue(Filter.mastered.matches(mastery: 0.8))
        XCTAssertTrue(Filter.all.matches(mastery: 0.5))
    }
}
