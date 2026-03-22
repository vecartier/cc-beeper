import SwiftUI

// MARK: - Theme Definition

struct ShellTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let shellImage: String  // filename in Resources: "shell-orange.png"
    let titleMain: String
    let titleGlow: String
    let titleShadow: String
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let themes: [ShellTheme] = [
        ShellTheme(id: "orange", name: "Orange",
                   shellImage: "shell-orange.png",
                   titleMain: "EBC7B1", titleGlow: "F0D8C8", titleShadow: "6A3A20"),
        ShellTheme(id: "pink", name: "Pink",
                   shellImage: "shell-pink.png",
                   titleMain: "F0C8D8", titleGlow: "F8E0E8", titleShadow: "6A2040"),
        ShellTheme(id: "blue", name: "Blue",
                   shellImage: "shell-blue.png",
                   titleMain: "B8D0F0", titleGlow: "D0E0F8", titleShadow: "203860"),
        ShellTheme(id: "green", name: "Green",
                   shellImage: "shell-green.png",
                   titleMain: "B8E8C8", titleGlow: "D0F0D8", titleShadow: "1A4828"),
        ShellTheme(id: "purple", name: "Purple",
                   shellImage: "shell-purple.png",
                   titleMain: "D0B8F0", titleGlow: "E0D0F8", titleShadow: "302060"),
        ShellTheme(id: "yellow", name: "Yellow",
                   shellImage: "shell-yellow.png",
                   titleMain: "F0E0B0", titleGlow: "F8ECC8", titleShadow: "605020"),
        ShellTheme(id: "mint", name: "Mint",
                   shellImage: "shell-mint.png",
                   titleMain: "B0E8E0", titleGlow: "C8F0E8", titleShadow: "184840"),
        ShellTheme(id: "black", name: "Black",
                   shellImage: "shell-black.png",
                   titleMain: "A0A0A0", titleGlow: "C0C0C0", titleShadow: "303030"),
        ShellTheme(id: "white", name: "White",
                   shellImage: "shell-white.png",
                   titleMain: "808080", titleGlow: "A0A0A0", titleShadow: "404040"),
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
        currentThemeId = UserDefaults.standard.string(forKey: "themeId") ?? "orange"
        darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    }

    // MARK: - Shell Image

    var shellImageName: String { theme.shellImage }

    // MARK: - Title Colors (used by PixelTitle if still rendered in code)

    var titleColor: Color { Color(hex: theme.titleMain) }
    var titleHighlight: Color { Color(hex: theme.titleGlow) }
    var titleShadow: Color { Color(hex: theme.titleShadow) }

    // MARK: - LCD Colors (dark mode only changes these)

    var lcdBg: Color { darkMode ? Color(hex: "1E2012") : Color(hex: "A8AA6A") }
    var lcdOn: Color { darkMode ? Color(hex: "7A8050") : Color(hex: "3A3A2E") }

    // MARK: - Legacy (kept for any code still referencing these)

    var shellColors: [Color] { [Color.clear] }
    var accentBase: Color { Color(hex: "1C1C1C") }
    var accentDark: Color { Color(hex: "141414") }
}
