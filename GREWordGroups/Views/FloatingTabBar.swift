import SwiftUI

enum AppTab: CaseIterable {
    case groups, drill, stats

    var title: String {
        switch self {
        case .groups: "Groups"
        case .drill: "Drill"
        case .stats: "Stats"
        }
    }

    @ViewBuilder
    var icon: some View {
        switch self {
        case .groups: Image(systemName: "square.grid.2x2")
        case .drill: Image(systemName: "bolt")
        case .stats: StatsGlyph().frame(width: 20, height: 20)
        }
    }
}

/// Three vertical bars of different heights, matching the design's Stats icon.
private struct StatsGlyph: View {
    var body: some View {
        Canvas { context, size in
            let unit = size.width / 24
            var path = Path()
            for (x, top) in [(5.0, 12.0), (12.0, 5.0), (19.0, 15.0)] {
                path.move(to: CGPoint(x: x * unit, y: 20 * unit))
                path.addLine(to: CGPoint(x: x * unit, y: top * unit))
            }
            context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 2 * unit * 1.1, lineCap: .round))
        }
    }
}

/// The floating capsule tab bar from the design.
struct FloatingTabBar: View {
    /// Space screens leave at the bottom of their content so it can scroll clear of the bar.
    static let clearance: CGFloat = 96

    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isSelected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 2) {
                        tab.icon
                            .font(.system(size: 19, weight: .medium))
                            .frame(height: 24)
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(width: 88, height: 52)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.ink)
                    .background(isSelected ? Theme.accentSoft : .clear, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.92), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
        .shadow(color: Theme.ink.opacity(0.10), radius: 12, y: 8)
        .padding(.bottom, 4)
    }
}
