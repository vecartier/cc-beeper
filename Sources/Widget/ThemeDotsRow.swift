import SwiftUI

struct ThemeDotsRow: View {
    @EnvironmentObject var themeManager: ThemeManager

    private let colorMap: [String: Color] = [
        "black": Color(hex: "212121"),
        "blue": Color(hex: "004FFA"),
        "green": Color(hex: "209B43"),
        "mint": Color(hex: "58D0C0"),
        "orange": Color(hex: "E86A1B"),
        "pink": Color(hex: "FD6295"),
        "purple": Color(hex: "6C22FF"),
        "red": Color(hex: "FF2222"),
        "white": Color(hex: "FFFFFF"),
        "yellow": Color(hex: "EDA623"),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ThemeManager.themes) { theme in
                let color = colorMap[theme.id] ?? .gray
                Button {
                    themeManager.currentThemeId = theme.id
                } label: {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                        if themeManager.currentThemeId == theme.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
