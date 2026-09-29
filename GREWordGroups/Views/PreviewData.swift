import SwiftData
import SwiftUI

/// In-memory data for SwiftUI previews, so the canvas never touches the real store.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: WordProgress.self, Stats.self,
                                      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    static let groups: [WordGroup] = (try? WordRepository.loadBundledGroups()) ?? []

    static func drillViewModel() -> DrillViewModel {
        let viewModel = DrillViewModel()
        viewModel.configure(groups: groups, store: ProgressStore(context: container.mainContext))
        return viewModel
    }
}
