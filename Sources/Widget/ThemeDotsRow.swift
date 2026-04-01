import SwiftUI

struct ThemeDotsRow: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ThemeManager.themes) { theme in
                let color = Color(hex: theme.dotColor)
                Button {
                    themeManager.currentThemeId = theme.id
                } label: {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                        if theme.id == "white" {
                            Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                .frame(width: 24, height: 24)
                        }
                        if themeManager.currentThemeId == theme.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(theme.id == "white" ? .black : .white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
