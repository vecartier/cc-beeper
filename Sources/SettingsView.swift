import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Audio") {
                SettingsAudioSection()
            }
            Section("Permissions") {
                SettingsPermissionsSection(viewModel: viewModel)
            }
            Section("Voice") {
                SettingsVoiceSection(viewModel: viewModel)
            }
            Section("About") {
                SettingsAboutSection()
            }
        }
        .frame(width: 460, height: 520)
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }
}
