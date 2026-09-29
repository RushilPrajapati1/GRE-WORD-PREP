import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: AppTab = .groups
    @State private var drill = DrillViewModel()
    @State private var groups: [WordGroup] = []
    @State private var loadError: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            tab(.groups) {
                GroupsView(groups: groups, streak: drill.streak, onDrill: startDrill)
            }
            tab(.drill) {
                DrillView(viewModel: drill)
            }
            tab(.stats) {
                StatsView(groups: groups, onDrill: startDrill, onReset: drill.resetProgress)
            }

            FloatingTabBar(selection: $selection)
        }
        .ignoresSafeArea(.keyboard)
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .preferredColorScheme(.light)
        .overlay {
            if let loadError {
                ContentUnavailableView("Couldn't Load Words", systemImage: "exclamationmark.triangle",
                                       description: Text(loadError))
                    .background(Theme.background)
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

    /// Keeps every tab alive (so navigation and scroll positions survive
    /// switching tabs) and shows only the selected one.
    private func tab(_ tab: AppTab, @ViewBuilder content: () -> some View) -> some View {
        let isSelected = selection == tab
        return content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
    }

    private func startDrill(_ groupID: Int?) {
        drill.focus(on: groupID)
        selection = .drill
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
