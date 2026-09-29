import SwiftData
import SwiftUI

struct GroupsView: View {
    let groups: [WordGroup]
    let streak: Int
    let onDrill: (Int?) -> Void

    @Query private var progress: [WordProgress]
    @State private var viewModel = GroupsViewModel()

    private var levels: [String: Int] {
        Dictionary(progress.map { ($0.word, $0.level) }, uniquingKeysWith: max)
    }

    var body: some View {
        let levels = levels
        let visible = viewModel.visibleGroups(groups, levels: levels)
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(eyebrow: "GRE Vocabulary", title: "Word Groups")

                    if let weakest = viewModel.weakestGroup(groups, levels: levels) {
                        UpNextCard(group: weakest, mastery: viewModel.mastery(of: weakest, levels: levels),
                                   streak: streak) { onDrill(weakest.id) }
                    }

                    SearchField(text: $viewModel.searchText)
                    FilterChips(selection: $viewModel.filter)

                    LazyVStack(spacing: 10) {
                        ForEach(visible) { group in
                            NavigationLink(value: group) {
                                GroupCard(group: group, mastery: viewModel.mastery(of: group, levels: levels))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if visible.isEmpty && !groups.isEmpty {
                        ContentUnavailableView("No Matching Groups", systemImage: "magnifyingglass",
                                               description: Text("Try a different search or filter."))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, FloatingTabBar.clearance)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Theme.background)
            .navigationTitle("Groups")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: WordGroup.self) { group in
                GroupDetailView(group: group, levels: levels, viewModel: viewModel, onDrill: onDrill)
            }
        }
    }
}

private struct UpNextCard: View {
    let group: WordGroup
    let mastery: Double
    let streak: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Up next · your weakest group").eyebrow(color: Theme.accentOnDark)
                    Spacer()
                    Label("\(streak)", systemImage: "flame")
                        .font(.system(size: 13, weight: .semibold))
                        .labelStyle(CompactLabelStyle())
                        .accessibilityLabel("Streak \(streak)")
                }
                Text(group.name)
                    .font(Theme.serif(26, .medium, relativeTo: .title))
                    .multilineTextAlignment(.leading)
                HStack(spacing: 12) {
                    Text("\(group.words.count) words · \(mastery.formatted(.percent.precision(.fractionLength(0)))) mastered")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accentOnDark)
                    Spacer()
                    Label("Start drill", systemImage: "bolt")
                        .font(.system(size: 15, weight: .semibold))
                        .labelStyle(CompactLabelStyle(spacing: 6))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .background(.white, in: Capsule())
                }
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Starts a drill on this group")
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
            TextField("Search groups or words", text: $text)
                .font(.system(size: 16))
                .foregroundStyle(Theme.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityLabel("Clear search")
            }
        }
        .foregroundStyle(Theme.secondaryInk)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Theme.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FilterChips: View {
    @Binding var selection: GroupsViewModel.Filter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GroupsViewModel.Filter.allCases) { filter in
                    let isSelected = filter == selection
                    Button(filter.rawValue) { selection = filter }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Theme.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(isSelected ? Theme.ink : Theme.surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(isSelected ? Theme.ink : Theme.border, lineWidth: 1))
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollClipDisabled()
    }
}

private struct GroupCard: View {
    let group: WordGroup
    let mastery: Double

    private var isMastered: Bool { mastery >= Theme.masteredThreshold }

    private var percentColor: Color {
        if isMastered { return Theme.success }
        return mastery == 0 ? Theme.secondaryInk : Theme.accent
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(group.name)
                        .font(.system(size: 17, weight: .semibold))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Text("\(group.words.count) words")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize()
                }
                Text(group.words.prefix(4).joined(separator: " · "))
                    .font(Theme.serif(16, .italic))
                    .foregroundStyle(Theme.secondaryInk)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    ProgressBar(value: mastery, color: isMastered ? Theme.success : Theme.accent)
                    Text(mastery.formatted(.percent.precision(.fractionLength(0))))
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(percentColor)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.top, 2)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.chevron)
        }
        .padding(16)
        .card()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(mastery.formatted(.percent.precision(.fractionLength(0)))) mastered")
    }
}

/// Icon and title side by side with tight spacing.
struct CompactLabelStyle: LabelStyle {
    var spacing: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}

#Preview {
    GroupsView(groups: PreviewData.groups, streak: 4) { _ in }
        .modelContainer(PreviewData.container)
}
