import Foundation
import SwiftData

/// Mastery level and answer history for a single word.
@Model
final class WordProgress {
    @Attribute(.unique) var word: String
    var level: Int
    var timesCorrect: Int
    var timesIncorrect: Int
    var lastReviewed: Date?

    init(word: String, level: Int = 0, timesCorrect: Int = 0, timesIncorrect: Int = 0, lastReviewed: Date? = nil) {
        self.word = word
        self.level = level
        self.timesCorrect = timesCorrect
        self.timesIncorrect = timesIncorrect
        self.lastReviewed = lastReviewed
    }
}
