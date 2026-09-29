import Foundation
import SwiftData

/// Lifetime drill totals. The app keeps a single instance.
@Model
final class Stats {
    var totalAnswered: Int
    var totalCorrect: Int
    var currentStreak: Int
    var bestStreak: Int
    var lastStudied: Date?

    init(totalAnswered: Int = 0, totalCorrect: Int = 0, currentStreak: Int = 0, bestStreak: Int = 0, lastStudied: Date? = nil) {
        self.totalAnswered = totalAnswered
        self.totalCorrect = totalCorrect
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastStudied = lastStudied
    }

    var accuracy: Double {
        totalAnswered == 0 ? 0 : Double(totalCorrect) / Double(totalAnswered)
    }

    var snapshot: StatsSnapshot {
        get {
            StatsSnapshot(totalAnswered: totalAnswered, totalCorrect: totalCorrect,
                          currentStreak: currentStreak, bestStreak: bestStreak)
        }
        set {
            totalAnswered = newValue.totalAnswered
            totalCorrect = newValue.totalCorrect
            currentStreak = newValue.currentStreak
            bestStreak = newValue.bestStreak
        }
    }
}
