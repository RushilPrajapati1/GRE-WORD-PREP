import CoreText
import SwiftUI

/// Colors, fonts and metrics from Design.html.
enum Theme {
    // MARK: Colors

    static let background = Color(hex: 0xF5F3EE)
    static let surface = Color.white
    static let ink = Color(hex: 0x1A1916)
    static let secondaryInk = Color(hex: 0x5F5B53)
    static let border = Color(hex: 0xE6E2D9)
    static let fill = Color(hex: 0xEAE7E0)
    static let chevron = Color(hex: 0xA8A399)

    static let accent = Color(hex: 0x2F43B8)
    static let accentSoft = Color(hex: 0xE7EAFB)
    static let accentInk = Color(hex: 0x1A2A8A)
    static let accentOnDark = Color(hex: 0xD6DBFA)

    static let success = Color(hex: 0x1F7A4D)
    static let successSoft = Color(hex: 0xE3F2EA)
    static let successInk = Color(hex: 0x145535)

    static let danger = Color(hex: 0xB3261E)
    static let dangerSoft = Color(hex: 0xFBE7E5)
    static let dangerInk = Color(hex: 0x8C1D18)

    static let streak = Color(hex: 0xB4520B)
    static let streakSoft = Color(hex: 0xFBEBDD)

    static let disabled = Color(hex: 0xDAD6CC)
    static let disabledInk = Color(hex: 0x4E4A43)

    /// Fill for each word level, 0 (new) through `DrillEngine.maxLevel` (mastered).
    static let levelColors: [Color] = [
        Color(hex: 0xDAD6CC), Color(hex: 0xC9CFF2), Color(hex: 0x9AA6E6),
        Color(hex: 0x6B7BD6), Color(hex: 0x3A4DBF), success,
    ]

    /// Groups at or above this mastery count as mastered.
    static let masteredThreshold = 0.8

    // MARK: Fonts

    enum SerifWeight: String {
        case regular = "Newsreader-Regular"
        case medium = "Newsreader-Medium"
        case semibold = "Newsreader-SemiBold"
        case italic = "Newsreader-Italic"
    }

    /// Newsreader, the serif used for titles, words and numbers.
    static func serif(_ size: CGFloat, _ weight: SerifWeight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        _ = fontsRegistered
        return .custom(weight.rawValue, size: size, relativeTo: style)
    }

    /// Registers the bundled fonts once. Done in code rather than Info.plist
    /// so SwiftUI previews get the fonts too.
    private static let fontsRegistered: Void = {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }()
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// White rounded card with the design's hairline border.
struct CardBackground: ViewModifier {
    var radius: CGFloat = 18
    var fill: Color = Theme.surface
    var stroke: Color = Theme.border

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(stroke, lineWidth: 1))
    }
}

extension View {
    func card(radius: CGFloat = 18, fill: Color = Theme.surface, stroke: Color = Theme.border) -> some View {
        modifier(CardBackground(radius: radius, fill: fill, stroke: stroke))
    }

    /// Small uppercase label, e.g. "GRE VOCABULARY".
    func eyebrow(color: Color = Theme.secondaryInk) -> some View {
        font(.system(size: 12, weight: .semibold))
            .tracking(0.96)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

/// Large screen header: eyebrow over a serif title.
struct ScreenHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(eyebrow).eyebrow()
            Text(title)
                .font(Theme.serif(38, .semibold, relativeTo: .largeTitle))
                .tracking(-0.38)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Thin rounded progress bar.
struct ProgressBar: View {
    let value: Double
    var height: CGFloat = 6
    var color: Color = Theme.accent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.fill)
                Capsule().fill(color)
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Five-segment level meter used on word chips.
struct LevelMeter: View {
    let level: Int

    var body: some View {
        let color = level >= DrillEngine.maxLevel ? Theme.success : Theme.accent
        HStack(spacing: 3) {
            ForEach(0..<DrillEngine.maxLevel, id: \.self) { index in
                Capsule()
                    .fill(index < level ? color : Theme.fill)
                    .frame(height: 4)
            }
        }
        .accessibilityHidden(true)
    }
}
