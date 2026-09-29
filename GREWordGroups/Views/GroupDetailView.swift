import SwiftUI

struct GroupDetailView: View {
    let group: WordGroup
    let levels: [String: Int]
    @Bindable var viewModel: GroupsViewModel
    let onDrill: (Int?) -> Void

    private var uniqueWords: Set<String> { Set(group.words) }

    var body: some View {
        let words = uniqueWords
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name)
                        .font(Theme.serif(34, .semibold, relativeTo: .largeTitle))
                        .accessibilityAddTraits(.isHeader)
                    Text(group.description)
                        .font(.system(size: 16))
                        .lineSpacing(3)
                        .foregroundStyle(Theme.secondaryInk)
                }

                HStack(spacing: 0) {
                    stat("\(words.count)", "Words")
                    Divider().overlay(Theme.border)
                    stat("\(words.filter { levels[$0] != nil }.count)", "Seen")
                    Divider().overlay(Theme.border)
                    stat("\(words.filter { (levels[$0] ?? 0) >= DrillEngine.maxLevel }.count)", "Mastered",
                         color: Theme.success)
                }
                .padding(.vertical, 14)
                .card()

                Button {
                    onDrill(group.id)
                } label: {
                    Label("Drill this group", systemImage: "bolt")
                        .labelStyle(CompactLabelStyle(spacing: 8))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                HStack {
                    Text("Words")
                        .font(.system(size: 20, weight: .semibold))
                    Spacer()
                    SortToggle(selection: $viewModel.wordSort)
                }
                .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.sortedWords(of: group, levels: levels), id: \.self) { word in
                        WordChip(word: word, level: levels[word] ?? 0)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, FloatingTabBar.clearance)
        }
        .background(Theme.background)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stat(_ value: String, _ label: String, color: Color = Theme.ink) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.serif(26, .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct SortToggle: View {
    @Binding var selection: GroupsViewModel.WordSort

    var body: some View {
        HStack(spacing: 0) {
            ForEach(GroupsViewModel.WordSort.allCases) { sort in
                let isSelected = sort == selection
                Button(sort.rawValue) { selection = sort }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(isSelected ? Theme.surface : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Theme.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct WordChip: View {
    let word: String
    let level: Int

    private var tag: String {
        switch level {
        case DrillEngine.maxLevel...: "Mastered"
        case 0: "New"
        default: "L\(level)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(word)
                    .font(Theme.serif(18, .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text(tag)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(level >= DrillEngine.maxLevel ? Theme.success : Theme.secondaryInk)
            }
            LevelMeter(level: level)
        }
        .padding(12)
        .card(radius: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(word), level \(level) of \(DrillEngine.maxLevel)")
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(group: PreviewData.groups[0],
                        levels: ["acclaim": 5, "extol": 3, "tout": 1],
                        viewModel: GroupsViewModel()) { _ in }
    }
}
