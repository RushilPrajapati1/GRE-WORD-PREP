import SwiftData
import SwiftUI

struct GroupsView: View {
    let groups: [WordGroup]
    let onDrill: (WordGroup) -> Void

    @Query private var progress: [WordProgress]
    @State private var viewModel = GroupsViewModel()

    private var levels: [String: Int] {
        Dictionary(progress.map { ($0.word, $0.level) }, uniquingKeysWith: max)
    }

    var body: some View {
        let levels = levels
        NavigationStack {
            List(viewModel.filteredGroups(groups)) { group in
                NavigationLink(value: group) {
                    GroupRow(group: group, mastery: viewModel.mastery(of: group, levels: levels))
                }
            }
            .navigationTitle("Word Groups")
            .navigationDestination(for: WordGroup.self) { group in
                GroupDetail(group: group, levels: levels, onDrill: onDrill)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search groups or words")
            .overlay {
                if !viewModel.searchText.isEmpty && viewModel.filteredGroups(groups).isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
        }
    }
}

private struct GroupRow: View {
    let group: WordGroup
    let mastery: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.name)
                    .font(.headline)
                Spacer()
                Text("\(group.words.count) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(group.words.prefix(4).joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            ProgressView(value: mastery)
                .tint(mastery >= 0.8 ? .green : .accentColor)
        }
        .padding(.vertical, 4)
    }
}

private struct GroupDetail: View {
    let group: WordGroup
    let levels: [String: Int]
    let onDrill: (WordGroup) -> Void

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(group.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button {
                    onDrill(group)
                } label: {
                    Label("Drill This Group", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(group.words, id: \.self) { word in
                        WordChip(word: word, level: levels[word] ?? 0)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WordChip: View {
    let word: String
    let level: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(word)
                .font(.callout.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 3) {
                ForEach(0..<DrillEngine.maxLevel, id: \.self) { index in
                    Capsule()
                        .fill(index < level ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(height: 4)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word), level \(level) of \(DrillEngine.maxLevel)")
    }
}

#Preview {
    GroupsView(groups: PreviewData.groups) { _ in }
        .modelContainer(PreviewData.container)
}
