import Foundation

/// One "pick the two words that belong" question.
struct DrillQuestion: Equatable, Sendable {
    let group: WordGroup
    /// All choices in display order: the correct answers mixed with trap words.
    let options: [String]
    let correctAnswers: Set<String>

    var trapWords: [String] { options.filter { !correctAnswers.contains($0) } }
}

/// The graded result of answering a `DrillQuestion`.
struct DrillOutcome: Equatable, Sendable {
    let isCorrect: Bool
    let correctPicks: Set<String>
    let wrongPicks: Set<String>
    let missed: Set<String>

    /// Whether the learner handled each word correctly: a correct answer counts
    /// only if it was picked, and a trap word counts against the learner if picked.
    var wordResults: [String: Bool] {
        var results: [String: Bool] = [:]
        for word in correctPicks { results[word] = true }
        for word in missed { results[word] = false }
        for word in wrongPicks { results[word] = false }
        return results
    }
}

struct StatsSnapshot: Equatable, Sendable {
    var totalAnswered = 0
    var totalCorrect = 0
    var currentStreak = 0
    var bestStreak = 0
}

/// Pure question-generation and scoring logic. No UI or persistence, so every
/// function can be unit tested with a seeded random number generator.
enum DrillEngine {
    static let optionCount = 6
    static let correctCount = 2
    static let maxLevel = 5

    // MARK: Question generation

    /// Builds a question with `correctCount` words from `target` and trap words
    /// taken only from other groups. Words shared between groups are never used
    /// as traps, so a trap can't also belong to the target group.
    /// Lower-level (weaker) words are more likely to be chosen as answers.
    ///
    /// When `trapGroups` is given (a combined drill), traps come from those groups
    /// first, topped up from `allGroups` if they don't have enough words.
    static func makeQuestion<R: RandomNumberGenerator>(
        target: WordGroup,
        allGroups: [WordGroup],
        trapGroups: [WordGroup]? = nil,
        levels: [String: Int] = [:],
        using rng: inout R
    ) -> DrillQuestion? {
        let targetWords = Set(target.words)
        let answerPool = unique(target.words)
        guard answerPool.count >= correctCount else { return nil }

        func trapWords(from groups: [WordGroup]) -> [String] {
            unique(groups.filter { $0.id != target.id }.flatMap(\.words))
                .filter { !targetWords.contains($0) }
        }
        let trapPool = trapWords(from: allGroups)
        let trapCount = optionCount - correctCount
        guard trapPool.count >= trapCount else { return nil }

        let answers = weightedSample(answerPool, count: correctCount, using: &rng) { word in
            Double(maxLevel + 1 - min(levels[word] ?? 0, maxLevel))
        }
        var traps = trapGroups.map { Array(trapWords(from: $0).shuffled(using: &rng).prefix(trapCount)) } ?? []
        if traps.count < trapCount {
            let taken = Set(traps)
            traps += trapPool.filter { !taken.contains($0) }.shuffled(using: &rng).prefix(trapCount - traps.count)
        }

        return DrillQuestion(
            group: target,
            options: (answers + traps).shuffled(using: &rng),
            correctAnswers: Set(answers)
        )
    }

    /// Picks the next group to drill, favoring groups with lower mastery.
    static func pickTargetGroup<R: RandomNumberGenerator>(
        from groups: [WordGroup],
        levels: [String: Int],
        using rng: inout R
    ) -> WordGroup? {
        let eligible = groups.filter { Set($0.words).count >= correctCount }
        return weightedSample(eligible, count: 1, using: &rng) { group in
            1 + (1 - mastery(of: group, levels: levels)) * Double(maxLevel)
        }.first
    }

    // MARK: Scoring

    static func score(_ question: DrillQuestion, selected: Set<String>) -> DrillOutcome {
        let picks = selected.intersection(question.options)
        return DrillOutcome(
            isCorrect: picks == question.correctAnswers,
            correctPicks: picks.intersection(question.correctAnswers),
            wrongPicks: picks.subtracting(question.correctAnswers),
            missed: question.correctAnswers.subtracting(picks)
        )
    }

    /// A correct answer moves a word up one level (capped at `maxLevel`);
    /// a wrong answer drops it one level (floored at 0).
    static func nextLevel(current: Int, wasCorrect: Bool) -> Int {
        let clamped = min(max(current, 0), maxLevel)
        return wasCorrect ? min(clamped + 1, maxLevel) : max(clamped - 1, 0)
    }

    static func updatedStats(_ stats: StatsSnapshot, isCorrect: Bool) -> StatsSnapshot {
        var next = stats
        next.totalAnswered += 1
        if isCorrect {
            next.totalCorrect += 1
            next.currentStreak += 1
            next.bestStreak = max(next.bestStreak, next.currentStreak)
        } else {
            next.currentStreak = 0
        }
        return next
    }

    /// Average word level in the group, from 0 (new) to 1 (fully mastered).
    static func mastery(of group: WordGroup, levels: [String: Int]) -> Double {
        let words = unique(group.words)
        guard !words.isEmpty else { return 0 }
        let total = words.reduce(0) { $0 + min(levels[$1] ?? 0, maxLevel) }
        return Double(total) / Double(words.count * maxLevel)
    }

    // MARK: Helpers

    /// Removes duplicates while keeping first-seen order, so results are
    /// deterministic for a given seed (unlike iterating a `Set`).
    private static func unique(_ words: [String]) -> [String] {
        var seen = Set<String>()
        return words.filter { seen.insert($0).inserted }
    }

    /// Weighted random sampling without replacement.
    private static func weightedSample<T, R: RandomNumberGenerator>(
        _ items: [T], count: Int, using rng: inout R, weight: (T) -> Double
    ) -> [T] {
        var pool = items.map { ($0, max(weight($0), .leastNonzeroMagnitude)) }
        var picked: [T] = []
        while picked.count < count, !pool.isEmpty {
            let total = pool.reduce(0) { $0 + $1.1 }
            var roll = Double.random(in: 0..<total, using: &rng)
            var index = pool.count - 1
            for (i, entry) in pool.enumerated() {
                if roll < entry.1 { index = i; break }
                roll -= entry.1
            }
            picked.append(pool.remove(at: index).0)
        }
        return picked
    }
}

/// Deterministic generator (SplitMix64) for reproducible questions in tests.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
