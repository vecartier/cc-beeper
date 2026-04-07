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
            primaryDisabled: useKokoro && viewModel.isTtsDownloading,
            skipLabel: nil,
            skipAction: nil,
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 10) {
                // Kokoro card
                Button { viewModel.ttsProvider = "kokoro" } label: {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            engineIcon(symbol: "waveform", color: ClaudeTheme.terracotta)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kokoro · On-device")
                                    .font(ClaudeTheme.sans(13, weight: .semibold))
                                    .foregroundStyle(ClaudeTheme.nearBlack)
                                if viewModel.isTtsDownloading {
                                    HStack(spacing: 5) {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                            .frame(width: 10, height: 10)
                                        Text("Downloading...")
                                    }
                                    .font(ClaudeTheme.sans(11))
                                    .foregroundStyle(ClaudeTheme.stone)
                                } else if viewModel.isTtsReady {
                                    Text("~930 MB · Ready")
                                        .font(ClaudeTheme.sans(11))
                                        .foregroundStyle(ClaudeTheme.green)
                                } else {
                                    Text("~930 MB · 9 languages · Natural voices")
                                        .font(ClaudeTheme.sans(11))
                                        .foregroundStyle(ClaudeTheme.stone)
                                }
                            }

                            Spacer()

                            if viewModel.isTtsReady {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(ClaudeTheme.green)
                            } else if !viewModel.isTtsDownloading {
                                Button(action: { viewModel.downloadKokoro() }) {
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

                        if useKokoro {
                            Divider().opacity(0.3)

                            HStack(spacing: 10) {
                                Text("Language")
                                    .font(ClaudeTheme.sans(12))
                                    .foregroundStyle(ClaudeTheme.stone)
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
                        engineIcon(symbol: "applelogo", color: ClaudeTheme.stone)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Speech")
                                .font(ClaudeTheme.sans(13, weight: .semibold))
                                .foregroundStyle(ClaudeTheme.nearBlack)
                            Text("No download · Built-in macOS voice")
                                .font(ClaudeTheme.sans(11))
                                .foregroundStyle(ClaudeTheme.stone)
                        }

                        Spacer()
                    }
                    .onboardingCardStyle(isSelected: !useKokoro)
                }
                .buttonStyle(.plain)

                // Language dependencies
                if useKokoro && viewModel.needsLangDeps && !viewModel.langDepsReady {
                    LangDepsCard(viewModel: viewModel)
                }
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
