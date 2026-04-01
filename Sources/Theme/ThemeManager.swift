import SwiftUI

// MARK: - Theme Definition

struct ShellTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let shellImage: String
    let dotColor: String  // hex for swatch
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let themes: [ShellTheme] = [
        ShellTheme(id: "black",  name: "Black",  displayName: "Midnight", shellImage: "beeper-black.png",  dotColor: "212121"),
        ShellTheme(id: "blue",   name: "Blue",   displayName: "Ocean",    shellImage: "beeper-blue.png",   dotColor: "004FFA"),
        ShellTheme(id: "green",  name: "Green",  displayName: "Pine",     shellImage: "beeper-green.png",  dotColor: "209B43"),
        ShellTheme(id: "mint",   name: "Mint",   displayName: "Slate",    shellImage: "beeper-mint.png",   dotColor: "58D0C0"),
        ShellTheme(id: "orange", name: "Orange", displayName: "Ember",    shellImage: "beeper-orange.png", dotColor: "E86A1B"),
        ShellTheme(id: "pink",   name: "Pink",   displayName: "Rose",     shellImage: "beeper-pink.png",   dotColor: "FD6295"),
        ShellTheme(id: "purple", name: "Purple", displayName: "Violet",   shellImage: "beeper-purple.png", dotColor: "6C22FF"),
        ShellTheme(id: "red",    name: "Red",    displayName: "Crimson",  shellImage: "beeper-red.png",    dotColor: "FF2222"),
        ShellTheme(id: "white",  name: "White",  displayName: "Ghost",    shellImage: "beeper-white.png",  dotColor: "FFFFFF"),
        ShellTheme(id: "yellow", name: "Yellow", displayName: "Gold",     shellImage: "beeper-yellow.png", dotColor: "EDA623"),
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
    var smallShellImageName: String { "beeper-small-\(currentThemeId).png" }

    // MARK: - LCD Colors (dark mode support)

    var lcdBg: Color { darkMode ? Color(hex: "1E2012") : Color(hex: "98D65A") }
    var lcdOn: Color { darkMode ? Color(hex: "7A8050") : Color(hex: "2A4A10") }
}
