import Foundation
import Observation

@MainActor
@Observable
final class DrillViewModel {
    enum OptionState {
        case idle, selected, correct, missed, wrong, dimmed
    }

    private(set) var groups: [WordGroup] = []
    private(set) var focusGroupID: Int?
    private(set) var question: DrillQuestion?
    private(set) var selection: Set<String> = []
    private(set) var outcome: DrillOutcome?
    private(set) var streak = 0

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
    func focus(on groupID: Int?) {
        guard focusGroupID != groupID || question == nil else { return }
        focusGroupID = groupID
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
        store?.record(result)
        streak = store?.stats().currentStreak ?? 0
    }

    func nextQuestion() {
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
        nextQuestion()
    }

    func state(for word: String) -> OptionState {
        guard let outcome else {
            return selection.contains(word) ? .selected : .idle
        }
        if outcome.correctPicks.contains(word) { return .correct }
        if outcome.missed.contains(word) { return .missed }
        if outcome.wrongPicks.contains(word) { return .wrong }
        return .dimmed
    }
}
