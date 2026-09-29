import Foundation
import SwiftData

/// Reads and writes `WordProgress` and `Stats` through SwiftData.
@MainActor
final class ProgressStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func levelsByWord() -> [String: Int] {
        let all = (try? context.fetch(FetchDescriptor<WordProgress>())) ?? []
        return Dictionary(all.map { ($0.word, $0.level) }, uniquingKeysWith: max)
    }

    func stats() -> Stats {
        if let existing = try? context.fetch(FetchDescriptor<Stats>()).first {
            return existing
        }
        let stats = Stats()
        context.insert(stats)
        return stats
    }

    func record(_ outcome: DrillOutcome, at date: Date = .now) {
        for (word, wasCorrect) in outcome.wordResults {
            let progress = progress(for: word)
            progress.level = DrillEngine.nextLevel(current: progress.level, wasCorrect: wasCorrect)
            if wasCorrect {
                progress.timesCorrect += 1
            } else {
                progress.timesIncorrect += 1
            }
            progress.lastReviewed = date
        }

        let stats = stats()
        stats.snapshot = DrillEngine.updatedStats(stats.snapshot, isCorrect: outcome.isCorrect)
        stats.lastStudied = date
        save()
    }

    func resetAll() {
        try? context.delete(model: WordProgress.self)
        try? context.delete(model: Stats.self)
        save()
    }

    private func progress(for word: String) -> WordProgress {
        var descriptor = FetchDescriptor<WordProgress>(predicate: #Predicate { $0.word == word })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let progress = WordProgress(word: word)
        context.insert(progress)
        return progress
    }

    private func save() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save progress: \(error)")
        }
    }
}
