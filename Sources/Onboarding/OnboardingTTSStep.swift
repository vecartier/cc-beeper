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
                            engineIcon(symbol: "waveform", color: OnboardingTheme.terracotta)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kokoro · On-device")
                                    .font(OnboardingTheme.sans(13, weight: .semibold))
                                    .foregroundStyle(OnboardingTheme.nearBlack)
                                if viewModel.isTtsDownloading {
                                    HStack(spacing: 6) {
                                        ProgressView()
                                            .controlSize(.small)
                                            .colorScheme(.dark)
                                        Text("Downloading (this may take a moment)...")
                                            .font(OnboardingTheme.sans(11))
                                            .foregroundStyle(OnboardingTheme.terracotta)
                                    }
                                } else if viewModel.isTtsReady {
                                    Text("~930 MB · Ready")
                                        .font(OnboardingTheme.sans(11))
                                        .foregroundStyle(OnboardingTheme.green)
                                } else {
                                    Text("~930 MB · 9 languages · Natural voices")
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
                .fill(OnboardingTheme.parchment)
                .frame(width: 34, height: 34)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Language dependencies

struct LangDepsCard: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.depsInstaller.isInstalling {
                HStack {
                    ProgressView().scaleEffect(0.7)
                    Text(viewModel.depsInstaller.installProgress)
                        .font(OnboardingTheme.sans(11))
                        .foregroundStyle(OnboardingTheme.stone)
                        .lineLimit(1)
                }
            } else {
                let langName = KokoroVoiceCatalog.languageNames[viewModel.selectedLangCode] ?? "This language"
                let sizeHint = viewModel.selectedLangCode == "j" ? " (~500 MB)" : " (~45 MB)"
                Text("\(langName) needs extra dependencies\(sizeHint).")
                    .font(OnboardingTheme.sans(11))
                    .foregroundStyle(OnboardingTheme.stone)

                Button("Install") { viewModel.installLangDeps() }
                    .buttonStyle(.bordered)
                    .tint(OnboardingTheme.terracotta)
                    .controlSize(.small)

                if let error = viewModel.depsInstaller.installError {
                    Text(error)
                        .font(OnboardingTheme.sans(11))
                        .foregroundStyle(OnboardingTheme.crimson)
                }
            }
        }
        .padding(12)
        .onboardingCard(radius: OnboardingTheme.radiusMedium)
    }
}
