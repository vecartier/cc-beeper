import SwiftUI

struct SettingsVoiceSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Button("Download Voices...") {
            viewModel.openSpokenContent()
        }
        .buttonStyle(.link)

        Text("Download premium voices like Ava (Premium) for better speech output.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
