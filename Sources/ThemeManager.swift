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
        // Orange shell + Purple accents (complementary)
        ShellTheme(id: "sunset", name: "Sunset",
                   shell: ["F09050", "E07838", "D06828", "C05820"],
                   accent: "6030A0", accentDark: "401870",
                   titleMain: "A060D0", titleGlow: "C890F0", titleShadow: "3A1060"),
        // Pink shell + Teal accents (complementary)
        ShellTheme(id: "sakura", name: "Sakura",
                   shell: ["F078A0", "E06088", "D05078", "C04068"],
                   accent: "208888", accentDark: "186068",
                   titleMain: "40B0B0", titleGlow: "70D8D8", titleShadow: "104848"),
        // Blue shell + Coral accents (complementary)
        ShellTheme(id: "ocean", name: "Ocean",
                   shell: ["5098F0", "3880E0", "2870D0", "2060C0"],
                   accent: "C05030", accentDark: "903820",
                   titleMain: "E08060", titleGlow: "F0A888", titleShadow: "602818"),
        // Green shell + Purple accents (complementary)
        ShellTheme(id: "forest", name: "Forest",
                   shell: ["58C878", "40B060", "30A050", "209040"],
                   accent: "8040A0", accentDark: "582878",
                   titleMain: "A868C8", titleGlow: "C898E0", titleShadow: "402058"),
        // Purple shell + Gold accents (complementary)
        ShellTheme(id: "lavender", name: "Lavender",
                   shell: ["A078F0", "8860E0", "7850D0", "6840C0"],
                   accent: "A08820", accentDark: "786018",
                   titleMain: "D0B840", titleGlow: "E8D070", titleShadow: "584010"),
        // Yellow shell + Indigo accents (complementary)
        ShellTheme(id: "honey", name: "Honey",
                   shell: ["F0C058", "E0A840", "D09830", "C08828"],
                   accent: "4838A0", accentDark: "302070",
                   titleMain: "6858C0", titleGlow: "9080E0", titleShadow: "281848"),
        // Teal shell + Rose accents (complementary)
        ShellTheme(id: "mint", name: "Mint",
                   shell: ["58D0C0", "40B8A8", "30A898", "209888"],
                   accent: "C04870", accentDark: "903050",
                   titleMain: "D06888", titleGlow: "E898B0", titleShadow: "582038"),
        // Magenta shell + Teal accents (complementary)
        ShellTheme(id: "berry", name: "Berry",
                   shell: ["D058C0", "B840A8", "A83098", "982888"],
                   accent: "209880", accentDark: "187060",
                   titleMain: "48C0A8", titleGlow: "78E0C8", titleShadow: "104838"),
        // Black shell + Cyan accents
        ShellTheme(id: "noir", name: "Noir",
                   shell: ["484848", "383838", "2C2C2C", "1E1E1E"],
                   accent: "2090A0", accentDark: "186878",
                   titleMain: "40C0D0", titleGlow: "78E0F0", titleShadow: "104850"),
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
