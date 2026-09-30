import SwiftData
import SwiftUI

struct StatsView: View {
    let groups: [WordGroup]
    let onDrill: (Set<Int>) -> Void
    let onReset: () -> Void

    @Query private var progress: [WordProgress]
    @Query private var stats: [Stats]
    @State private var confirmingReset = false

    var body: some View {
        let summary = StatsViewModel(groups: groups, progress: progress, stats: stats.first)
        ScrollView {
            VStack(spacing: 14) {
                ScreenHeader(eyebrow: "Your progress", title: "Stats")
                AccuracyCard(summary: summary)

                HStack(spacing: 10) {
                    StreakCard(title: "Current streak", value: summary.currentStreak, showsFlame: true)
                    StreakCard(title: "Best streak", value: summary.bestStreak, showsFlame: false)
                }

                WordLevelsCard(summary: summary)
                NeedsWorkCard(entries: summary.weakestGroups, onDrill: onDrill)

                Button {
                    confirmingReset = true
                } label: {
                    Label("Reset progress", systemImage: "arrow.counterclockwise")
                        .labelStyle(CompactLabelStyle(spacing: 8))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.danger)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .card(radius: 16)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, FloatingTabBar.clearance)
        }
        .background(Theme.background)
        .confirmationDialog("Reset all progress?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive, action: onReset)
        } message: {
            Text("This clears every word level and your drill history.")
        }
    }
}

private struct AccuracyCard: View {
    let summary: StatsViewModel

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().stroke(Theme.fill, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: summary.accuracy)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(summary.accuracy.formatted(.percent.precision(.fractionLength(0))))
                    .font(Theme.serif(30, .semibold))
            }
            .padding(5)
            .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: 4) {
                Text("Accuracy")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.78)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.secondaryInk)
                Text("**\(summary.totalCorrect)** correct of **\(summary.totalAnswered)** answered")
                    .font(.system(size: 16))
                Group {
                    if let lastStudied = summary.lastStudied {
                        Text("Last studied \(lastStudied, format: .relative(presentation: .named))")
                    } else {
                        Text("No drills yet")
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .card(radius: 22)
        .accessibilityElement(children: .combine)
    }
}

private struct StreakCard: View {
    let title: String
    let value: Int
    let showsFlame: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if showsFlame {
                    Image(systemName: "flame")
                        .foregroundStyle(Theme.streak)
                }
                Text(title)
            }
            .font(.system(size: 13))
            .foregroundStyle(Theme.secondaryInk)
            Text("\(value)")
                .font(Theme.serif(32, .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .card()
        .accessibilityElement(children: .combine)
    }
}

private struct WordLevelsCard: View {
    let summary: StatsViewModel

    private func label(for level: Int) -> String {
        switch level {
        case 0: "New"
        case DrillEngine.maxLevel: "Mastered"
        default: "L\(level)"
        }
    }

    var body: some View {
        let counts = summary.levelCounts
        let total = max(counts.reduce(0, +), 1)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Words")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("\(summary.wordsSeen) of \(summary.totalWords) seen")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryInk)
            }

            GeometryReader { proxy in
                let visible = counts.indices.filter { counts[$0] > 0 }
                let gaps = CGFloat(max(visible.count - 1, 0)) * 2
                HStack(spacing: 2) {
                    ForEach(visible, id: \.self) { level in
                        Rectangle()
                            .fill(Theme.levelColors[level])
                            .frame(width: (proxy.size.width - gaps) * CGFloat(counts[level]) / CGFloat(total))
                    }
                }
            }
            .frame(height: 14)
            .clipShape(Capsule())
            .accessibilityHidden(true)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .leading), count: 3),
                      alignment: .leading, spacing: 10) {
                ForEach(counts.indices, id: \.self) { level in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.levelColors[level])
                            .frame(width: 10, height: 10)
                        Text(label(for: level))
                            .foregroundStyle(Theme.secondaryInk)
                        Text("\(counts[level])")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(18)
        .card(radius: 22)
    }
}

private struct NeedsWorkCard: View {
    let entries: [(group: WordGroup, mastery: Double)]
    let onDrill: (Set<Int>) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Needs work")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Drill these") { onDrill(Set(entries.map(\.group.id))) }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHint("Drills these groups together")
            }
            .frame(height: 44)

            ForEach(entries, id: \.group.id) { entry in
                Button {
                    onDrill([entry.group.id])
                } label: {
                    HStack(spacing: 12) {
                        Text(entry.group.name)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ProgressBar(value: entry.mastery, height: 5)
                            .frame(width: 56)
                        Text(entry.mastery.formatted(.percent.precision(.fractionLength(0))))
                            .font(.system(size: 13))
                            .monospacedDigit()
                            .foregroundStyle(Theme.secondaryInk)
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    .frame(minHeight: 48)
                    .overlay(alignment: .top) { Rectangle().fill(Theme.border).frame(height: 1) }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Drills this group")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .card(radius: 22)
    }
}

#Preview {
    StatsView(groups: PreviewData.groups, onDrill: { _ in }, onReset: {})
        .modelContainer(PreviewData.container)
}
