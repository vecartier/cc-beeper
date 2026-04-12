import SwiftUI

struct OnboardingTTSStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var useKokoro: Bool { viewModel.ttsProvider == "kokoro" }

    private var sortedLangCodes: [(code: String, name: String)] {
        KokoroVoiceCatalog.languageNames
            .map { (code: $0.key, name: $0.value) }
            .sorted { a, b in
                if a.code == "a" { return true }
                if b.code == "a" { return false }
                return a.name < b.name
            }
    }

    var body: some View {
        OnboardingShell(
            stepNumber: 7,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Text-to-speech engine",
            subtitle: "CC-Beeper can read Claude's responses aloud. Kokoro runs on-device with natural-sounding voices.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            primaryDisabled: useKokoro && !viewModel.isTtsReady,
            skipLabel: nil,
            skipAction: nil,
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 10) {
                // Kokoro card
                Button { viewModel.ttsProvider = "kokoro" } label: {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            engineIcon(symbol: "waveform", color: OnboardingTheme.terracotta)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kokoro · On-device")
                                    .font(OnboardingTheme.sans(13, weight: .semibold))
                                    .foregroundStyle(OnboardingTheme.nearBlack)
                                if viewModel.isTtsDownloading {
                                    HStack(spacing: 8) {
                                        Text("Downloading \(Int(viewModel.ttsDownloadFraction * 100))%...")
                                            .font(OnboardingTheme.sans(11))
                                            .foregroundStyle(OnboardingTheme.terracotta)
                                            .monospacedDigit()
                                        ProgressView(value: viewModel.ttsDownloadFraction)
                                            .progressViewStyle(.linear)
                                            .tint(OnboardingTheme.terracotta)
                                            .frame(width: 120)
                                    }
                                } else if viewModel.isTtsReady {
                                    Text("~650 MB · Ready")
                                        .font(OnboardingTheme.sans(11))
                                        .foregroundStyle(OnboardingTheme.green)
                                } else if let err = viewModel.ttsDownloadError {
                                    Text("Download failed — \(err)")
                                        .font(OnboardingTheme.sans(11))
                                        .foregroundStyle(OnboardingTheme.terracotta)
                                        .lineLimit(2)
                                } else {
                                    Text("~650 MB · 9 languages · Natural voices")
                                        .font(OnboardingTheme.sans(11))
                                        .foregroundStyle(OnboardingTheme.stone)
                                }
                            }

                            Spacer()

                            if viewModel.isTtsReady {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(OnboardingTheme.green)
                            } else if !viewModel.isTtsDownloading {
                                Button(action: { viewModel.downloadKokoro() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: viewModel.ttsDownloadError == nil ? "arrow.down" : "arrow.clockwise")
                                            .font(.system(size: 10, weight: .semibold))
                                        Text(viewModel.ttsDownloadError == nil ? "Download" : "Retry")
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

                        if useKokoro {
                            Divider().opacity(0.3)

                            HStack(spacing: 10) {
                                Text("Language")
                                    .font(OnboardingTheme.sans(12))
                                    .foregroundStyle(OnboardingTheme.stone)
                                Spacer()
                                Picker("", selection: $viewModel.selectedLangCode) {
                                    ForEach(sortedLangCodes, id: \.code) { lang in
                                        Text(lang.name).tag(lang.code)
                                    }
                                }
                                .pickerStyle(.menu)
                                .colorScheme(.light)
                                .frame(maxWidth: 180)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .onboardingCardStyle(isSelected: useKokoro)
                }
                .buttonStyle(.plain)

                // Apple Speech card
                Button { viewModel.ttsProvider = "apple" } label: {
                    HStack(spacing: 12) {
                        engineIcon(symbol: "applelogo", color: OnboardingTheme.stone)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Speech")
                                .font(OnboardingTheme.sans(13, weight: .semibold))
                                .foregroundStyle(OnboardingTheme.nearBlack)
                            Text("No download · Built-in macOS voice")
                                .font(OnboardingTheme.sans(11))
                                .foregroundStyle(OnboardingTheme.stone)
                        }

                        Spacer()
                    }
                    .onboardingCardStyle(isSelected: !useKokoro)
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
