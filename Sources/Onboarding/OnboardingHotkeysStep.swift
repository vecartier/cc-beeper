import SwiftUI

struct OnboardingHotkeysStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingShell(
            stepNumber: 7,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Keep these hotkeys?",
            subtitle: "Use them from any app. Remap anytime in Settings.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            skipLabel: "Skip",
            skipAction: { viewModel.goNext() },
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 6) {
                OnboardingHotkeyPill(action: "Approve permission", key: $viewModel.hotkeyAccept)
                OnboardingHotkeyPill(action: "Deny permission", key: $viewModel.hotkeyDeny)
                OnboardingHotkeyPill(action: "Dictation", key: $viewModel.hotkeyVoice)
                OnboardingHotkeyPill(action: "Go to terminal", key: $viewModel.hotkeyTerminal)
                OnboardingHotkeyPill(action: "Read over / Stop", key: $viewModel.hotkeyMute)

                if !viewModel.isAccessibilityGranted {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(OnboardingTheme.amber)
                            .font(.system(size: 10))
                        Text("Accessibility permission required for hotkeys to work.")
                            .font(OnboardingTheme.sans(10))
                            .foregroundStyle(OnboardingTheme.stone)
                    }
                    .padding(.top, 6)
                }
            }
            .frame(maxWidth: 460)
        }
    }
}

// MARK: - Hotkey Pill

private struct OnboardingHotkeyPill: View {
    let action: String
    @Binding var key: String

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text(action)
                .font(OnboardingTheme.sans(12))
                .foregroundStyle(OnboardingTheme.nearBlack)

            Spacer()

            Button {
                if isRecording { stopRecording() } else { startRecording() }
            } label: {
                HStack(spacing: 3) {
                    Text("⌥")
                        .font(OnboardingTheme.mono(11))
                        .foregroundStyle(OnboardingTheme.stone)
                    Text(isRecording ? "..." : key)
                        .font(OnboardingTheme.mono(12, weight: .semibold))
                        .foregroundStyle(OnboardingTheme.nearBlack)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingTheme.radiusSmall, style: .continuous)
                        .fill(isRecording ? OnboardingTheme.terracotta.opacity(0.15) : OnboardingTheme.ivory)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OnboardingTheme.radiusSmall, style: .continuous)
                        .strokeBorder(isRecording ? OnboardingTheme.terracotta : OnboardingTheme.ringWarm, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .onboardingCard(radius: OnboardingTheme.radiusMedium)
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }
            if let chars = event.charactersIgnoringModifiers?.uppercased(),
               chars.count == 1,
               chars.first?.isLetter == true {
                key = chars
                stopRecording()
                return nil
            }
            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
