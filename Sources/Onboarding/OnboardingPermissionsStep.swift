import SwiftUI

struct OnboardingPermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)

                VStack(spacing: 8) {
                    Text("Permissions")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("CC-Beeper works best with these, but none are required.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    PermissionRow(
                        isGranted: viewModel.isAccessibilityGranted,
                        name: "Accessibility",
                        description: "Global hotkeys and text injection",
                        onGrant: {
                            viewModel.requestAccessibility()
                            viewModel.openAccessibilitySettings()
                        }
                    )

                    PermissionRow(
                        isGranted: viewModel.isMicGranted,
                        name: "Microphone",
                        description: "Voice input for talking to Claude",
                        onGrant: {
                            viewModel.requestMicrophone()
                            viewModel.openMicrophoneSettings()
                        }
                    )

                    PermissionRow(
                        isGranted: viewModel.isSpeechGranted,
                        name: "Speech Recognition",
                        description: "On-device speech-to-text",
                        onGrant: {
                            viewModel.requestSpeechRecognition()
                            viewModel.openSpeechSettings()
                        }
                    )
                }
                .padding(.horizontal, 48)

                Spacer()
            }

            OnboardingFooter(
                primaryLabel: "Next",
                primaryAction: { viewModel.goNext() },
                primaryDisabled: !viewModel.allPermissionsGranted,
                showSkip: true,
                skipAction: { viewModel.goNext() }
            )
        }
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }
}

private struct PermissionRow: View {
    let isGranted: Bool
    let name: String
    let description: String
    let onGrant: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isGranted ? .green : .secondary)
                .font(.title2)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isGranted {
                Button("Grant") { onGrant() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
