import Foundation
import Observation

@MainActor
@Observable
final class DrillViewModel {
    enum OptionState {
        case idle, selected, correct, missed, wrong, trap
    }

    enum SegmentState {
        case correct, wrong, current, upcoming
    }

    private(set) var groups: [WordGroup] = []
    private(set) var focusGroupID: Int?
    private(set) var question: DrillQuestion?
    private(set) var selection: Set<String> = []
    private(set) var outcome: DrillOutcome?
    private(set) var streak = 0
    private(set) var session = DrillSession()

    private var store: ProgressStore?
    private var rng = SystemRandomNumberGenerator()

    var focusGroup: WordGroup? {
        groups.first { $0.id == focusGroupID }
    }

    var canSubmit: Bool {
        outcome == nil && selection.count == DrillEngine.correctCount
    }

    func configure(groups: [WordGroup], store: ProgressStore) {
        guard self.store == nil else { return }
        self.groups = groups
        self.store = store
        streak = store.stats().currentStreak
        nextQuestion()
    }

    /// Restricts drilling to one group, or pass `nil` to drill all groups.
    /// Changing the focus starts a new session.
    func focus(on groupID: Int?) {
        guard focusGroupID != groupID || question == nil else { return }
        focusGroupID = groupID
        session.reset()
        nextQuestion()
    }

    func toggle(_ word: String) {
        guard outcome == nil else { return }
        if selection.contains(word) {
            selection.remove(word)
        } else if selection.count < DrillEngine.correctCount {
            selection.insert(word)
        }
    }

    func submit() {
        guard canSubmit, let question else { return }
        let result = DrillEngine.score(question, selected: selection)
        outcome = result
        session.record(isCorrect: result.isCorrect)
        store?.record(result)
        streak = store?.stats().currentStreak ?? 0
    }

    func nextQuestion() {
        if session.isComplete {
            session.reset()
        }
        let levels = store?.levelsByWord() ?? [:]
        let target = focusGroup ?? DrillEngine.pickTargetGroup(from: groups, levels: levels, using: &rng)
        question = target.flatMap {
            DrillEngine.makeQuestion(target: $0, allGroups: groups, levels: levels, using: &rng)
        }
        selection = []
        outcome = nil
    }

    func resetProgress() {
        store?.resetAll()
        streak = 0
        session.reset()
        nextQuestion()
    }

    // MARK: Display

    /// The question number shown as "Question n of 10".
    var questionNumber: Int {
        outcome == nil ? min(session.answeredCount + 1, session.length) : session.answeredCount
    }

    var progressHint: String {
        if outcome == nil {
            return "\(selection.count) of \(DrillEngine.correctCount) selected"
        }
        return session.isComplete ? "\(session.correctCount) of \(session.length) correct" : ""
    }

    var actionTitle: String {
        if outcome == nil { return "Check answer" }
        return session.isComplete ? "Start new session" : "Next question"
    }

    func segment(at index: Int) -> SegmentState {
        if index < session.results.count {
            return session.results[index] ? .correct : .wrong
        }
        return index == session.results.count && outcome == nil ? .current : .upcoming
    }

    func state(for word: String) -> OptionState {
        guard let outcome else {
            return selection.contains(word) ? .selected : .idle
        }
        if outcome.correctPicks.contains(word) { return .correct }
        if outcome.missed.contains(word) { return .missed }
        if outcome.wrongPicks.contains(word) { return .wrong }
        return .trap
    }

    /// After answering, each option says which group it belongs to.
    func caption(for word: String) -> String? {
        switch state(for: word) {
        case .idle, .selected: nil
        case .correct: "In this group"
        case .missed: "Missed · in this group"
        case .wrong, .trap: owningGroupName(of: word)
        }
    }

    var resultTitle: String {
        outcome?.isCorrect == true ? "Correct" : "Not quite"
    }

    var resultMessage: String {
        guard let question else { return "" }
        let answers = question.options.filter { question.correctAnswers.contains($0) }
        let list = answers.formatted(.list(type: .and))
        if outcome?.isCorrect == true {
            let meaning = question.group.name.split(separator: ",").first.map { $0.lowercased() } ?? ""
            return "\(list) both mean \(meaning). Both move up a level."
        }
        return "The answers were \(list). Each wrong option shows the group it belongs to."
    }

    private func owningGroupName(of word: String) -> String? {
        groups.first { $0.id != question?.group.id && $0.words.contains(word) }?.name
    }
}
