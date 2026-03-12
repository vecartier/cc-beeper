import SwiftUI

// MARK: - Theme Definition

struct ShellTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let shell: [String]
    let accent: String
    let accentDark: String
    let titleMain: String
    let titleGlow: String
    let titleShadow: String
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let themes: [ShellTheme] = [
        ShellTheme(id: "sunset", name: "Sunset",
                   shell: ["F09050", "E07838", "D06828", "C05820"],
                   accent: "6030A0", accentDark: "401870",
                   titleMain: "A060D0", titleGlow: "C890F0", titleShadow: "3A1060"),
        ShellTheme(id: "sakura", name: "Sakura",
                   shell: ["F078A0", "E06088", "D05078", "C04068"],
                   accent: "A03070", accentDark: "702050",
                   titleMain: "D068A8", titleGlow: "F098C8", titleShadow: "601848"),
        ShellTheme(id: "ocean", name: "Ocean",
                   shell: ["5098F0", "3880E0", "2870D0", "2060C0"],
                   accent: "304898", accentDark: "183070",
                   titleMain: "68A8E0", titleGlow: "98C8F8", titleShadow: "102850"),
        ShellTheme(id: "forest", name: "Forest",
                   shell: ["58C878", "40B060", "30A050", "209040"],
                   accent: "308848", accentDark: "186830",
                   titleMain: "68C890", titleGlow: "98E8B8", titleShadow: "104028"),
        ShellTheme(id: "lavender", name: "Lavender",
                   shell: ["A078F0", "8860E0", "7850D0", "6840C0"],
                   accent: "5838A0", accentDark: "382070",
                   titleMain: "A088E8", titleGlow: "C0A8FF", titleShadow: "281048"),
        ShellTheme(id: "honey", name: "Honey",
                   shell: ["F0C058", "E0A840", "D09830", "C08828"],
                   accent: "987830", accentDark: "685020",
                   titleMain: "D0B868", titleGlow: "F0D898", titleShadow: "584020"),
        ShellTheme(id: "mint", name: "Mint",
                   shell: ["58D0C0", "40B8A8", "30A898", "209888"],
                   accent: "309080", accentDark: "186858",
                   titleMain: "68C8C0", titleGlow: "98E8E0", titleShadow: "104840"),
        ShellTheme(id: "berry", name: "Berry",
                   shell: ["D058C0", "B840A8", "A83098", "982888"],
                   accent: "7830A0", accentDark: "501870",
                   titleMain: "C068D0", titleGlow: "E098F0", titleShadow: "401058"),
    ]

    @Published var currentThemeId: String {
        didSet { UserDefaults.standard.set(currentThemeId, forKey: "themeId") }
    }
    @Published var darkMode: Bool {
        didSet { UserDefaults.standard.set(darkMode, forKey: "darkMode") }
    }

    var theme: ShellTheme {
        Self.themes.first { $0.id == currentThemeId } ?? Self.themes[0]
    }

    init() {
        currentThemeId = UserDefaults.standard.string(forKey: "themeId") ?? "sunset"
        darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    }

    // MARK: - Computed Colors

    var shellColors: [Color] {
        theme.shell.map { darkMode ? Self.darken($0, by: 0.6) : Color(hex: $0) }
    }

    var accentBase: Color {
        darkMode ? Self.darken(theme.accent, by: 0.2) : Color(hex: theme.accent)
    }

    var accentDark: Color {
        darkMode ? Self.darken(theme.accentDark, by: 0.2) : Color(hex: theme.accentDark)
    }

    var titleColor: Color { Color(hex: theme.titleMain) }
    var titleHighlight: Color { Color(hex: theme.titleGlow) }
    var titleShadow: Color { Color(hex: theme.titleShadow) }

    var lcdBg: Color { darkMode ? Color(hex: "1E2012") : Color(hex: "A8AA6A") }
    var lcdOn: Color { darkMode ? Color(hex: "7A8050") : Color(hex: "3A3A2E") }

    // MARK: - Helpers

    private static func darken(_ hex: String, by factor: Double) -> Color {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r = Double(int >> 16) / 255 * (1 - factor)
        let g = Double(int >> 8 & 0xFF) / 255 * (1 - factor)
        let b = Double(int & 0xFF) / 255 * (1 - factor)
        return Color(.sRGB, red: r, green: g, blue: b)
    }
}
