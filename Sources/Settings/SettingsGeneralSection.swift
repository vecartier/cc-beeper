import SwiftUI

struct SettingsThemeSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Section("Shell Color") {
            ThemeDotsRow()
                .padding(.vertical, 4)
        }

        Section {
            Toggle("Dark Mode", isOn: $themeManager.darkMode)
                .toggleStyle(.switch)
        }
    }
}
