import Foundation
import Observation

@MainActor
@Observable
final class GroupsViewModel {
    var searchText = ""

    func filteredGroups(_ groups: [WordGroup]) -> [WordGroup] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return groups }
        return groups.filter { group in
            group.name.localizedCaseInsensitiveContains(query)
                || group.words.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    func mastery(of group: WordGroup, levels: [String: Int]) -> Double {
        DrillEngine.mastery(of: group, levels: levels)
    }
}
