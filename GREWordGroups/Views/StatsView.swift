import SwiftData
import SwiftUI

struct StatsView: View {
    let groups: [WordGroup]
    let onReset: () -> Void

    @Query private var progress: [WordProgress]
    @Query private var stats: [Stats]
    @State private var confirmingReset = false

    var body: some View {
        let summary = StatsViewModel(groups: groups, progress: progress, stats: stats.first)
        NavigationStack {
            List {
                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatTile(title: "Accuracy", value: summary.accuracy.formatted(.percent.precision(.fractionLength(0))))
                        StatTile(title: "Answered", value: "\(summary.totalAnswered)")
                        StatTile(title: "Streak", value: "\(summary.currentStreak)")
                        StatTile(title: "Best Streak", value: "\(summary.bestStreak)")
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Words") {
                    LabeledContent("Seen", value: "\(summary.wordsSeen) of \(summary.totalWords)")
                    LabeledContent("Mastered", value: "\(summary.masteredWords)")
                    LevelChart(counts: summary.levelCounts)
                        .padding(.vertical, 8)
                }

                Section("Needs Work") {
                    ForEach(summary.weakestGroups, id: \.group.id) { entry in
                        HStack {
                            Text(entry.group.name)
                            Spacer()
                            Text(entry.mastery.formatted(.percent.precision(.fractionLength(0))))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                if let lastStudied = summary.lastStudied {
                    Section {
                        LabeledContent("Last studied", value: lastStudied.formatted(.relative(presentation: .named)))
                    }
                }

                Section {
                    Button("Reset Progress", role: .destructive) { confirmingReset = true }
                }
            }
            .navigationTitle("Stats")
            .confirmationDialog("Reset all progress?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive, action: onReset)
            } message: {
                Text("This clears every word level and your drill history.")
            }
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct LevelChart: View {
    let counts: [Int]

    var body: some View {
        let maxCount = max(counts.max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(counts.indices, id: \.self) { level in
                VStack(spacing: 4) {
                    Text("\(counts[level])")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(level == counts.count - 1 ? Color.green : Color.accentColor)
                        .frame(height: max(4, 90 * CGFloat(counts[level]) / CGFloat(maxCount)))
                    Text("L\(level)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 130, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(counts.enumerated().map { "Level \($0.offset): \($0.element) words" }.joined(separator: ", "))
    }
}

#Preview {
    StatsView(groups: PreviewData.groups) {}
        .modelContainer(PreviewData.container)
}
