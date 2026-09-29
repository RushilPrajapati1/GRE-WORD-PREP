import Foundation
import Observation

@MainActor
@Observable
final class GroupsViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case inProgress = "In progress"
        case notStarted = "Not started"
        case mastered = "Mastered"

        var id: Self { self }

        func matches(mastery: Double) -> Bool {
            switch self {
            case .all: true
            case .notStarted: mastery == 0
            case .mastered: mastery >= Theme.masteredThreshold
            case .inProgress: mastery > 0 && mastery < Theme.masteredThreshold
            }
        }
    }

    enum WordSort: String, CaseIterable, Identifiable {
        case weakest = "Weakest"
        case alphabetical = "A–Z"

        var id: Self { self }
    }

    var searchText = ""
    var filter: Filter = .all
    var wordSort: WordSort = .weakest

    func visibleGroups(_ groups: [WordGroup], levels: [String: Int]) -> [WordGroup] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return groups.filter { group in
            let matchesQuery = query.isEmpty
                || group.name.localizedCaseInsensitiveContains(query)
                || group.words.contains { $0.localizedCaseInsensitiveContains(query) }
            return matchesQuery && filter.matches(mastery: mastery(of: group, levels: levels))
        }
    }

    func mastery(of group: WordGroup, levels: [String: Int]) -> Double {
        DrillEngine.mastery(of: group, levels: levels)
    }

    /// The group with the lowest mastery, shown in the "Up next" card.
    func weakestGroup(_ groups: [WordGroup], levels: [String: Int]) -> WordGroup? {
        groups.min { lhs, rhs in
            let left = mastery(of: lhs, levels: levels)
            let right = mastery(of: rhs, levels: levels)
            return left == right ? lhs.id < rhs.id : left < right
        }
    }

    func sortedWords(of group: WordGroup, levels: [String: Int]) -> [String] {
        var seen = Set<String>()
        let words = group.words.filter { seen.insert($0).inserted }
        switch wordSort {
        case .alphabetical:
            return words.sorted { $0.localizedCompare($1) == .orderedAscending }
        case .weakest:
            return words.sorted { lhs, rhs in
                let left = levels[lhs] ?? 0
                let right = levels[rhs] ?? 0
                return left == right ? lhs.localizedCompare(rhs) == .orderedAscending : left < right
            }
        }
    }
}
