import SwiftUI

/// Lets the learner pick several groups to drill together.
struct GroupPickerSheet: View {
    let groups: [WordGroup]
    let masteries: [Int: Double]
    let onApply: (Set<Int>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: Set<Int>

    init(groups: [WordGroup], masteries: [Int: Double], selection: Set<Int>, onApply: @escaping (Set<Int>) -> Void) {
        self.groups = groups
        self.masteries = masteries
        self.onApply = onApply
        _draft = State(initialValue: selection)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    quickPicks

                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryInk)

                    LazyVStack(spacing: 8) {
                        ForEach(groups) { group in
                            GroupPickerRow(group: group,
                                           mastery: masteries[group.id] ?? 0,
                                           isSelected: draft.contains(group.id)) {
                                toggle(group.id)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("Choose groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Drill") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(Theme.accent)
        .presentationDragIndicator(.visible)
    }

    private var summary: String {
        switch draft.count {
        case 0: "Drilling every group."
        case 1: "Drilling one group."
        default: "Questions rotate through these \(draft.count) groups, and the wrong options come from the others, so you learn to tell them apart."
        }
    }

    private var quickPicks: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All groups", isOn: draft.isEmpty) { draft = [] }
                chip("Weakest 3", isOn: draft == weakest(3)) { draft = weakest(3) }
                chip("Weakest 5", isOn: draft == weakest(5)) { draft = weakest(5) }
                chip("Weakest 10", isOn: draft == weakest(10)) { draft = weakest(10) }
            }
        }
        .scrollClipDisabled()
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isOn ? .white : Theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(isOn ? Theme.ink : Theme.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isOn ? Theme.ink : Theme.border, lineWidth: 1))
            .buttonStyle(.plain)
            .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func weakest(_ count: Int) -> Set<Int> {
        let ranked = groups.sorted { lhs, rhs in
            let left = masteries[lhs.id] ?? 0
            let right = masteries[rhs.id] ?? 0
            return left == right ? lhs.id < rhs.id : left < right
        }
        return Set(ranked.prefix(count).map(\.id))
    }

    private func toggle(_ id: Int) {
        if draft.contains(id) {
            draft.remove(id)
        } else {
            draft.insert(id)
        }
    }
}

private struct GroupPickerRow: View {
    let group: WordGroup
    let mastery: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.chevron)
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    Text("\(group.words.count) words · \(mastery.formatted(.percent.precision(.fractionLength(0)))) mastered")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryInk)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .card(radius: 16,
                  fill: isSelected ? Theme.accentSoft : Theme.surface,
                  stroke: isSelected ? Theme.accent : Theme.border)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    GroupPickerSheet(groups: PreviewData.groups, masteries: [1: 0.4, 2: 0.1],
                     selection: [1, 2]) { _ in }
}
