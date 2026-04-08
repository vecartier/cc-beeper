import SwiftUI

struct OnboardingPermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingShell(
            stepNumber: 5,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Grant these permissions?",
            subtitle: "Not required now, but they unlock hotkeys, dictation, and voice. You can enable them later in Settings.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            primaryDisabled: !viewModel.allPermissionsGranted,
            skipLabel: "Not Now",
            skipAction: { viewModel.goNext() },
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 8) {
                PermissionRow(
                    isGranted: viewModel.isAccessibilityGranted,
                    name: "Accessibility",
                    description: "For global hotkeys from any app.",
                    onGrant: {
                        viewModel.requestAccessibility()
                        viewModel.openAccessibilitySettings()
                    }
                )
                PermissionRow(
                    isGranted: viewModel.isMicGranted,
                    name: "Microphone",
                    description: "To dictate prompts into Claude.",
                    onGrant: {
                        viewModel.requestMicrophone()
                        viewModel.openMicrophoneSettings()
                    }
                )
                PermissionRow(
                    isGranted: viewModel.isSpeechGranted,
                    name: "Speech Recognition",
                    description: "Fallback when Whisper can't be used.",
                    onGrant: {
                        viewModel.requestSpeechRecognition()
                        viewModel.openSpeechSettings()
                    }
                )
            }
            .frame(maxWidth: 460)
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
        HStack(spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isGranted ? OnboardingTheme.green : OnboardingTheme.warmSilver)
                .font(.system(size: 18))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(OnboardingTheme.sans(12, weight: .medium))
                    .foregroundStyle(OnboardingTheme.nearBlack)
                Text(description)
                    .font(OnboardingTheme.sans(11))
                    .foregroundStyle(OnboardingTheme.stone)
            }

            Spacer()

            if isGranted {
                StatusBadge(text: "Granted", color: OnboardingTheme.green)
            } else {
                Button("Grant") { onGrant() }
                    .buttonStyle(.bordered)
                    .tint(OnboardingTheme.terracotta)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .onboardingCard(radius: OnboardingTheme.radiusMedium)
    }
}

private struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(OnboardingTheme.mono(9, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.12))
            )
    }
}
