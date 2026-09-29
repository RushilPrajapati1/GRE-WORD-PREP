import SwiftData
import SwiftUI

struct ContentView: View {
    enum Tab: Hashable {
        case groups, drill, stats
    }

    @Environment(\.modelContext) private var modelContext
    @State private var selection: Tab = .groups
    @State private var drill = DrillViewModel()
    @State private var groups: [WordGroup] = []
    @State private var loadError: String?

    var body: some View {
        TabView(selection: $selection) {
            GroupsView(groups: groups) { group in
                drill.focus(on: group.id)
                selection = .drill
            }
            .tabItem { Label("Groups", systemImage: "square.grid.2x2") }
            .tag(Tab.groups)

            DrillView(viewModel: drill)
                .tabItem { Label("Drill", systemImage: "bolt.fill") }
                .tag(Tab.drill)

            StatsView(groups: groups, onReset: drill.resetProgress)
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)
        }
        .overlay {
            if let loadError {
                ContentUnavailableView("Couldn't Load Words", systemImage: "exclamationmark.triangle",
                                       description: Text(loadError))
                    .background(.background)
            }
        }
        .task {
            guard groups.isEmpty else { return }
            do {
                groups = try WordRepository.loadBundledGroups()
                drill.configure(groups: groups, store: ProgressStore(context: modelContext))
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
