import SwiftUI

// MARK: - Theme Definition

struct ShellTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let shellImage: String
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let themes: [ShellTheme] = [
        ShellTheme(id: "black", name: "Black", shellImage: "beeper-black.png"),
        ShellTheme(id: "orange", name: "Orange", shellImage: "beeper-orange.png"),
        ShellTheme(id: "blue", name: "Blue", shellImage: "beeper-blue.png"),
        ShellTheme(id: "green", name: "Green", shellImage: "beeper-green.png"),
        ShellTheme(id: "purple", name: "Purple", shellImage: "beeper-purple.png"),
        ShellTheme(id: "red", name: "Red", shellImage: "beeper-red.png"),
        ShellTheme(id: "white", name: "White", shellImage: "beeper-white.png"),
        ShellTheme(id: "yellow", name: "Yellow", shellImage: "beeper-yellow.png"),
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
        currentThemeId = UserDefaults.standard.string(forKey: "themeId") ?? "black"
        darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    }

    var shellImageName: String { theme.shellImage }

    // MARK: - LCD Colors (dark mode support)

    var lcdBg: Color { darkMode ? Color(hex: "1E2012") : Color(hex: "98D65A") }
    var lcdOn: Color { darkMode ? Color(hex: "7A8050") : Color(hex: "2A4A10") }
}
