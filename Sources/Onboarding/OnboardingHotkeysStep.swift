import SwiftUI

struct OnboardingHotkeysStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "keyboard.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.primary)

                VStack(spacing: 6) {
                    Text("Hotkeys")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Stay in flow — handle Claude without switching windows.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 6) {
                    OnboardingHotkeyPill(action: "Accept permission", key: $viewModel.hotkeyAccept)
                    OnboardingHotkeyPill(action: "Deny permission", key: $viewModel.hotkeyDeny)
                    OnboardingHotkeyPill(action: "Voice record", key: $viewModel.hotkeyVoice)
                    OnboardingHotkeyPill(action: "Go to terminal", key: $viewModel.hotkeyTerminal)
                    OnboardingHotkeyPill(action: "Read over / Stop", key: $viewModel.hotkeyMute)
                }
                .padding(.horizontal, 56)

                if !viewModel.isAccessibilityGranted {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 10))
                        Text("Accessibility permission required for hotkeys to work.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            OnboardingFooter(
                primaryLabel: "Next",
                primaryAction: { viewModel.goNext() },
                showSkip: true,
                skipAction: { viewModel.goNext() }
            )
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
                .font(.system(size: 13))

            Spacer()

            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                HStack(spacing: 3) {
                    Text("⌥")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(isRecording ? "..." : key)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? AppConstants.accent.opacity(0.15) : Color.primary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? AppConstants.accent : .clear, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
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
