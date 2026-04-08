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
                        engineIcon(symbol: "waveform", color: OnboardingTheme.terracotta)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("WhisperKit · On-device")
                                .font(OnboardingTheme.sans(13, weight: .semibold))
                                .foregroundStyle(OnboardingTheme.nearBlack)
                            if viewModel.isSttDownloading {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .controlSize(.small)
                                        .colorScheme(.dark)
                                    Text("Downloading (this may take a moment)...")
                                        .font(OnboardingTheme.sans(11))
                                        .foregroundStyle(OnboardingTheme.terracotta)
                                }
                            } else if viewModel.isSttReady {
                                Text("~500 MB · Ready")
                                    .font(OnboardingTheme.sans(11))
                                    .foregroundStyle(OnboardingTheme.green)
                            } else {
                                Text("~500 MB · 99 languages · Best accuracy")
                                    .font(OnboardingTheme.sans(11))
                                    .foregroundStyle(OnboardingTheme.stone)
                            }
                        }

                        Spacer()

                        if viewModel.isSttReady {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(OnboardingTheme.green)
                        } else if !viewModel.isSttDownloading {
                            Button(action: { viewModel.downloadWhisper() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("Download")
                                }
                                .font(OnboardingTheme.sans(12, weight: .semibold))
                                .foregroundStyle(OnboardingTheme.nearBlack)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(OnboardingTheme.ivory))
                                .overlay(Capsule().strokeBorder(OnboardingTheme.ringWarm, lineWidth: 1))
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
                        engineIcon(symbol: "applelogo", color: OnboardingTheme.stone)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Speech")
                                .font(OnboardingTheme.sans(13, weight: .semibold))
                                .foregroundStyle(OnboardingTheme.nearBlack)
                            Text("No download · Built-in macOS speech")
                                .font(OnboardingTheme.sans(11))
                                .foregroundStyle(OnboardingTheme.stone)
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
                .fill(OnboardingTheme.parchment)
                .frame(width: 34, height: 34)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }
}
