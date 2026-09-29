import Foundation

/// Summary figures for the Stats tab, derived from persisted progress.
struct StatsViewModel {
    let accuracy: Double
    let totalAnswered: Int
    let totalCorrect: Int
    let currentStreak: Int
    let bestStreak: Int
    let lastStudied: Date?
    let totalWords: Int
    let masteredWords: Int
    let wordsSeen: Int
    /// Number of words at each level, index 0...DrillEngine.maxLevel. Unseen words count as level 0.
    let levelCounts: [Int]
    let weakestGroups: [(group: WordGroup, mastery: Double)]

    init(groups: [WordGroup], progress: [WordProgress], stats: Stats?) {
        let allWords = Set(groups.flatMap(\.words))
        let levels = Dictionary(progress.map { ($0.word, $0.level) }, uniquingKeysWith: max)
            .filter { allWords.contains($0.key) }

        accuracy = stats?.accuracy ?? 0
        totalAnswered = stats?.totalAnswered ?? 0
        totalCorrect = stats?.totalCorrect ?? 0
        currentStreak = stats?.currentStreak ?? 0
        bestStreak = stats?.bestStreak ?? 0
        lastStudied = stats?.lastStudied
        totalWords = allWords.count
        wordsSeen = levels.count
        masteredWords = levels.values.filter { $0 >= DrillEngine.maxLevel }.count

        var counts = Array(repeating: 0, count: DrillEngine.maxLevel + 1)
        for word in allWords {
            counts[min(max(levels[word] ?? 0, 0), DrillEngine.maxLevel)] += 1
        }
        levelCounts = counts

        let ranked: [(group: WordGroup, mastery: Double)] = groups.map { group in
            (group: group, mastery: DrillEngine.mastery(of: group, levels: levels))
        }
        weakestGroups = Array(ranked.sorted(by: Self.weakerFirst).prefix(5))
    }

    private static func weakerFirst(_ lhs: (group: WordGroup, mastery: Double),
                                    _ rhs: (group: WordGroup, mastery: Double)) -> Bool {
        if lhs.mastery != rhs.mastery {
            return lhs.mastery < rhs.mastery
        }
        return lhs.group.id < rhs.group.id
    }
}
