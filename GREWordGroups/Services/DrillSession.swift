import Foundation

/// Tracks a fixed-length run of drill questions (the 10-segment bar on the Drill tab).
struct DrillSession: Equatable, Sendable {
    let length: Int
    private(set) var results: [Bool] = []

    init(length: Int = 10) {
        self.length = length
    }

    var answeredCount: Int { results.count }
    var correctCount: Int { results.filter { $0 }.count }
    var isComplete: Bool { results.count >= length }

    mutating func record(isCorrect: Bool) {
        guard !isComplete else { return }
        results.append(isCorrect)
    }

    mutating func reset() {
        results = []
    }
}
