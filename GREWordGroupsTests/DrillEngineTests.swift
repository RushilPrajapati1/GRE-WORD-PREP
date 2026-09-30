import XCTest
@testable import GREWordGroups

final class DrillEngineTests: XCTestCase {
    private let praise = WordGroup(id: 1, name: "Praise", description: "Praise words",
                                   words: ["extol", "laud", "commend", "champion", "acclaim"])
    private let support = WordGroup(id: 2, name: "Support", description: "Support words",
                                    words: ["bolster", "buttress", "champion", "foster"])
    private let calm = WordGroup(id: 3, name: "Calm", description: "Calm words",
                                 words: ["placate", "mollify", "assuage", "commend"])
    private let bold = WordGroup(id: 4, name: "Bold", description: "Bold words",
                                 words: ["audacious", "intrepid", "valiant"])

    private var groups: [WordGroup] { [praise, support, calm, bold] }

    // MARK: Question generation

    func testTrapWordsAreNeverInTargetGroup() {
        // "champion" and "commend" also appear in other groups; they must never be traps for Praise.
        for seed in 0..<500 {
            var rng = SeededGenerator(seed: UInt64(seed))
            for target in groups {
                guard let question = DrillEngine.makeQuestion(target: target, allGroups: groups, using: &rng) else {
                    continue
                }
                for trap in question.trapWords {
                    XCTAssertFalse(target.words.contains(trap), "Trap '\(trap)' belongs to \(target.name) (seed \(seed))")
                }
            }
        }
    }

    func testExactlyTwoCorrectOptionsFromTargetGroup() throws {
        for seed in 0..<500 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let question = try XCTUnwrap(DrillEngine.makeQuestion(target: praise, allGroups: groups, using: &rng))

            XCTAssertEqual(question.correctAnswers.count, 2)
            XCTAssertTrue(question.correctAnswers.isSubset(of: Set(praise.words)))
            XCTAssertEqual(question.options.filter { praise.words.contains($0) }.count, 2)
            XCTAssertEqual(question.options.count, DrillEngine.optionCount)
            XCTAssertEqual(Set(question.options).count, question.options.count, "Options must be unique")
        }
    }

    func testBundledDataAlwaysProducesValidQuestions() throws {
        let bundled = try WordRepository.loadBundledGroups()
        XCTAssertFalse(bundled.isEmpty)

        var rng = SeededGenerator(seed: 42)
        for target in bundled {
            let question = try XCTUnwrap(DrillEngine.makeQuestion(target: target, allGroups: bundled, using: &rng))
            XCTAssertEqual(question.options.filter { target.words.contains($0) }.count, 2, target.name)
        }
    }

    func testSameSeedProducesSameQuestion() {
        var first = SeededGenerator(seed: 7)
        var second = SeededGenerator(seed: 7)
        XCTAssertEqual(DrillEngine.makeQuestion(target: praise, allGroups: groups, using: &first),
                       DrillEngine.makeQuestion(target: praise, allGroups: groups, using: &second))
    }

    func testReturnsNilWhenNotEnoughTraps() {
        var rng = SeededGenerator(seed: 1)
        XCTAssertNil(DrillEngine.makeQuestion(target: praise, allGroups: [praise, bold], using: &rng))
    }

    func testReturnsNilWhenGroupHasFewerThanTwoWords() {
        let tiny = WordGroup(id: 99, name: "Tiny", description: "", words: ["solo"])
        var rng = SeededGenerator(seed: 1)
        XCTAssertNil(DrillEngine.makeQuestion(target: tiny, allGroups: groups + [tiny], using: &rng))
    }

    func testWeakerWordsArePreferredAsAnswers() throws {
        var levels = Dictionary(uniqueKeysWithValues: praise.words.map { ($0, DrillEngine.maxLevel) })
        levels["extol"] = 0
        var picks = 0
        for seed in 0..<300 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let question = try XCTUnwrap(DrillEngine.makeQuestion(target: praise, allGroups: groups,
                                                                  levels: levels, using: &rng))
            if question.correctAnswers.contains("extol") { picks += 1 }
        }
        // Uniform sampling would pick "extol" ~40% of the time; weighting should push it well above that.
        XCTAssertGreaterThan(picks, 200)
    }

    // MARK: Combined drills

    func testCombinedDrillTakesTrapsFromChosenGroups() throws {
        let chosen = [praise, calm, bold]
        let chosenWords = Set(calm.words + bold.words)
        for seed in 0..<300 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let question = try XCTUnwrap(DrillEngine.makeQuestion(target: praise, allGroups: groups,
                                                                  trapGroups: chosen, using: &rng))
            // Calm + Bold have 6 words, but "commend" is also in Praise, leaving 5 for the 4 traps.
            XCTAssertTrue(Set(question.trapWords).isSubset(of: chosenWords), "seed \(seed)")
            XCTAssertFalse(question.trapWords.contains { praise.words.contains($0) }, "seed \(seed)")
            XCTAssertEqual(question.correctAnswers.count, 2)
        }
    }

    func testCombinedDrillTopsUpTrapsWhenChosenGroupsAreTooSmall() throws {
        let tiny = WordGroup(id: 5, name: "Tiny", description: "", words: ["terse", "laconic"])
        let all = groups + [tiny]
        for seed in 0..<300 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let question = try XCTUnwrap(DrillEngine.makeQuestion(target: praise, allGroups: all,
                                                                  trapGroups: [praise, tiny], using: &rng))
            XCTAssertEqual(question.trapWords.count, DrillEngine.optionCount - DrillEngine.correctCount)
            XCTAssertTrue(Set(["terse", "laconic"]).isSubset(of: Set(question.trapWords)), "seed \(seed)")
            XCTAssertFalse(question.trapWords.contains { praise.words.contains($0) }, "seed \(seed)")
            XCTAssertEqual(Set(question.options).count, question.options.count)
        }
    }

    // MARK: Scoring

    private func sampleQuestion() -> DrillQuestion {
        DrillQuestion(group: praise,
                      options: ["extol", "bolster", "laud", "placate", "audacious", "foster"],
                      correctAnswers: ["extol", "laud"])
    }

    func testScoringBothCorrect() {
        let outcome = DrillEngine.score(sampleQuestion(), selected: ["extol", "laud"])
        XCTAssertTrue(outcome.isCorrect)
        XCTAssertEqual(outcome.correctPicks, ["extol", "laud"])
        XCTAssertTrue(outcome.wrongPicks.isEmpty)
        XCTAssertTrue(outcome.missed.isEmpty)
        XCTAssertEqual(outcome.wordResults, ["extol": true, "laud": true])
    }

    func testScoringOneCorrectOneTrapIsIncorrect() {
        let outcome = DrillEngine.score(sampleQuestion(), selected: ["extol", "bolster"])
        XCTAssertFalse(outcome.isCorrect)
        XCTAssertEqual(outcome.correctPicks, ["extol"])
        XCTAssertEqual(outcome.wrongPicks, ["bolster"])
        XCTAssertEqual(outcome.missed, ["laud"])
        XCTAssertEqual(outcome.wordResults, ["extol": true, "bolster": false, "laud": false])
    }

    func testScoringBothTraps() {
        let outcome = DrillEngine.score(sampleQuestion(), selected: ["placate", "foster"])
        XCTAssertFalse(outcome.isCorrect)
        XCTAssertTrue(outcome.correctPicks.isEmpty)
        XCTAssertEqual(outcome.missed, ["extol", "laud"])
    }

    func testScoringIgnoresWordsNotInOptions() {
        let outcome = DrillEngine.score(sampleQuestion(), selected: ["extol", "laud", "nonsense"])
        XCTAssertTrue(outcome.isCorrect)
        XCTAssertTrue(outcome.wrongPicks.isEmpty)
    }

    // MARK: Levels

    func testLevelIncreasesOnCorrect() {
        XCTAssertEqual(DrillEngine.nextLevel(current: 0, wasCorrect: true), 1)
        XCTAssertEqual(DrillEngine.nextLevel(current: 3, wasCorrect: true), 4)
    }

    func testLevelCapsAtMax() {
        XCTAssertEqual(DrillEngine.nextLevel(current: DrillEngine.maxLevel, wasCorrect: true), DrillEngine.maxLevel)
    }

    func testLevelDropsOnIncorrectAndFloorsAtZero() {
        XCTAssertEqual(DrillEngine.nextLevel(current: 3, wasCorrect: false), 2)
        XCTAssertEqual(DrillEngine.nextLevel(current: 0, wasCorrect: false), 0)
    }

    func testLevelClampsOutOfRangeInput() {
        XCTAssertEqual(DrillEngine.nextLevel(current: 99, wasCorrect: true), DrillEngine.maxLevel)
        XCTAssertEqual(DrillEngine.nextLevel(current: -4, wasCorrect: false), 0)
    }

    // MARK: Stats

    func testStatsTrackStreaks() {
        var stats = StatsSnapshot()
        for isCorrect in [true, true, true, false, true] {
            stats = DrillEngine.updatedStats(stats, isCorrect: isCorrect)
        }
        XCTAssertEqual(stats, StatsSnapshot(totalAnswered: 5, totalCorrect: 4, currentStreak: 1, bestStreak: 3))
    }

    func testMastery() {
        XCTAssertEqual(DrillEngine.mastery(of: bold, levels: [:]), 0)
        let full = Dictionary(uniqueKeysWithValues: bold.words.map { ($0, DrillEngine.maxLevel) })
        XCTAssertEqual(DrillEngine.mastery(of: bold, levels: full), 1)
        XCTAssertEqual(DrillEngine.mastery(of: bold, levels: ["audacious": 3, "intrepid": 3]), 0.4, accuracy: 0.0001)
    }

    func testPickTargetGroupFavorsLowMastery() throws {
        // Words shared between groups ("champion", "commend") appear more than once here.
        let mastered = Dictionary((praise.words + support.words + calm.words).map { ($0, DrillEngine.maxLevel) },
                                  uniquingKeysWith: { first, _ in first })
        var boldCount = 0
        for seed in 0..<300 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let pick = try XCTUnwrap(DrillEngine.pickTargetGroup(from: groups, levels: mastered, using: &rng))
            if pick == bold { boldCount += 1 }
        }
        // Bold weight is 6 vs 1 for each mastered group, so it should win ~2/3 of the time.
        XCTAssertGreaterThan(boldCount, 150)
    }
}
