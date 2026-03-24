import SwiftUI

struct SettingsPermissionsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        PermissionRow(
            icon: "accessibility",
            label: "Accessibility",
            isGranted: viewModel.isAccessibilityGranted,
            openSettings: { viewModel.openAccessibilitySettings() }
        )

        PermissionRow(
            icon: "mic.fill",
            label: "Microphone",
            isGranted: viewModel.isMicGranted,
            openSettings: { viewModel.openMicrophoneSettings() }
        )

        PermissionRow(
            icon: "waveform.circle.fill",
            label: "Speech Recognition",
            isGranted: viewModel.isSpeechGranted,
            openSettings: { viewModel.openSpeechSettings() }
        )
    }
}

private struct PermissionRow: View {
    let icon: String
    let label: String
    let isGranted: Bool
    let openSettings: () -> Void

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
            Toggle("", isOn: .constant(isGranted))
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(isGranted)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isGranted {
                openSettings()
            }
        }
    }
}
