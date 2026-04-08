import SwiftUI

// MARK: - Onboarding Theme
//
// Warm, parchment-based palette used throughout the onboarding flow.

enum ClaudeTheme {

    // MARK: Colors — warm neutrals, no cool blues

    /// Canvas: warm paper-toned background.
    static let parchment = Color(hex: "F5F4ED")

    /// Surface: slightly warmer than white for cards and inset panels.
    static let ivory = Color(hex: "FAF9F5")

    /// Primary text — near-black with a warm undertone.
    static let nearBlack = Color(hex: "141413")

    /// Primary CTA color — warm terracotta.
    static let terracotta = Color(hex: "C96442")

    /// Accent — softer than terracotta, used for highlights.
    static let coral = Color(hex: "D97757")

    /// Secondary text — warm stone gray.
    static let stone = Color(hex: "87867F")

    /// Tertiary text and hints — lighter warm gray.
    static let warmSilver = Color(hex: "B0AEA5")

    /// Border / hairline — warm cream.
    static let borderCream = Color(hex: "E8E6DC")

    /// Ring / focus border — one shade darker than borderCream.
    static let ringWarm = Color(hex: "D1CFC5")

    /// Warm sand — background for the window chrome / footer area.
    static let warmSand = Color(hex: "E8E6DC")

    /// Success green (warm toned).
    static let green = Color(hex: "5C8A4D")

    /// Warning amber (warm toned).
    static let amber = Color(hex: "C4903D")

    /// Error crimson (warm toned).
    static let crimson = Color(hex: "B53333")

    // MARK: Fonts — editorial serif/sans split

    /// Serif display font for headlines (uses Apple's New York).
    static func serif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Sans body font (system default).
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Mono font for keys / code.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: Radii — 8pt base scale

    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXLarge: CGFloat = 24

    // MARK: Spacing

    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 24
    static let space6: CGFloat = 32
    static let space8: CGFloat = 48
    static let space10: CGFloat = 64
}

// MARK: - Card Background Modifier

/// Ring-shadow card: ivory fill with a warm hairline border.
struct ClaudeCard: ViewModifier {
    var radius: CGFloat = ClaudeTheme.radiusMedium
    var fillColor: Color = ClaudeTheme.ivory

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(ClaudeTheme.borderCream, lineWidth: 1)
            )
    }
}

extension View {
    func claudeCard(radius: CGFloat = ClaudeTheme.radiusMedium,
                    fillColor: Color = ClaudeTheme.ivory) -> some View {
        modifier(ClaudeCard(radius: radius, fillColor: fillColor))
    }
}
