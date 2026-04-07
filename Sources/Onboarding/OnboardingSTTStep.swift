import SwiftUI

struct OnboardingSTTStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var useWhisper: Bool { viewModel.sttProvider == "whisper" }

    var body: some View {
        OnboardingShell(
            stepNumber: 6,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Speech recognition",
            subtitle: "How CC-Beeper transcribes your voice when you dictate. WhisperKit runs fully on-device with better accuracy.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            primaryDisabled: useWhisper && viewModel.isSttDownloading,
            skipLabel: nil,
            skipAction: nil,
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 10) {
                // WhisperKit card
                Button { viewModel.sttProvider = "whisper" } label: {
                    HStack(spacing: 12) {
                        engineIcon(symbol: "waveform", color: ClaudeTheme.terracotta)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("WhisperKit · On-device")
                                .font(ClaudeTheme.sans(13, weight: .semibold))
                                .foregroundStyle(ClaudeTheme.nearBlack)
                            if viewModel.isSttDownloading {
                                HStack(spacing: 5) {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: 10, height: 10)
                                    Text("Downloading...")
                                }
                                .font(ClaudeTheme.sans(11))
                                .foregroundStyle(ClaudeTheme.stone)
                            } else if viewModel.isSttReady {
                                Text("~500 MB · Ready")
                                    .font(ClaudeTheme.sans(11))
                                    .foregroundStyle(ClaudeTheme.green)
                            } else {
                                Text("~500 MB · 99 languages · Best accuracy")
                                    .font(ClaudeTheme.sans(11))
                                    .foregroundStyle(ClaudeTheme.stone)
                            }
                        }

                        Spacer()

                        if viewModel.isSttReady {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(ClaudeTheme.green)
                        } else if !viewModel.isSttDownloading {
                            Button(action: { viewModel.downloadWhisper() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("Download")
                                }
                                .font(ClaudeTheme.sans(12, weight: .semibold))
                                .foregroundStyle(ClaudeTheme.nearBlack)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(ClaudeTheme.ivory))
                                .overlay(Capsule().strokeBorder(ClaudeTheme.ringWarm, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onboardingCardStyle(isSelected: useWhisper)
                }
                .buttonStyle(.plain)

                // Apple Speech card
                Button { viewModel.sttProvider = "apple" } label: {
                    HStack(spacing: 12) {
                        engineIcon(symbol: "applelogo", color: ClaudeTheme.stone)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Speech")
                                .font(ClaudeTheme.sans(13, weight: .semibold))
                                .foregroundStyle(ClaudeTheme.nearBlack)
                            Text("No download · Built-in macOS speech")
                                .font(ClaudeTheme.sans(11))
                                .foregroundStyle(ClaudeTheme.stone)
                        }

                        Spacer()
                    }
                    .onboardingCardStyle(isSelected: !useWhisper)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 460)
        }
    }

    private func engineIcon(symbol: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ClaudeTheme.parchment)
                .frame(width: 34, height: 34)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }
}
