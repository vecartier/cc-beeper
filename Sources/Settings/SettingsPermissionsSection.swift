import SwiftUI

struct SettingsPermissionsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        PermissionRow(
            icon: "accessibility",
            label: "Accessibility",
            hint: "Privacy & Security → Accessibility",
            isGranted: viewModel.isAccessibilityGranted,
            openSettings: { viewModel.openAccessibilitySettings() }
        )

        PermissionRow(
            icon: "mic.fill",
            label: "Microphone",
            hint: "Privacy & Security → Microphone",
            isGranted: viewModel.isMicGranted,
            openSettings: { viewModel.openMicrophoneSettings() }
        )

        PermissionRow(
            icon: "waveform.circle.fill",
            label: "Speech Recognition",
            hint: "Privacy & Security → Speech Recognition",
            isGranted: viewModel.isSpeechGranted,
            openSettings: { viewModel.openSpeechSettings() }
        )
    }
}

private struct PermissionRow: View {
    let icon: String
    let label: String
    var hint: String = ""
    let isGranted: Bool
    let openSettings: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label(label, systemImage: icon)
                if !isGranted && !hint.isEmpty {
                    Text(hint)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            Toggle("", isOn: Binding(
                get: { isGranted },
                set: { _ in if !isGranted { openSettings() } }
            ))
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}
