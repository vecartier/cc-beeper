import SwiftUI

struct OnboardingVoiceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

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
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)

                VStack(spacing: 8) {
                    Text("Voice Setup")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose how CC-Beeper handles voice.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Model status
                if viewModel.isModelReady {
                    Label("AI Models Ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout.weight(.semibold))

                } else if viewModel.isModelDownloading {
                    VStack(spacing: 12) {
                        ProgressView(value: viewModel.modelDownloadProgress)
                            .progressViewStyle(.linear)
                            .tint(AppConstants.accent)
                            .padding(.horizontal, 48)

                        Text(viewModel.modelDownloadPhase)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                } else {
                    VStack(spacing: 12) {
                        Button {
                            viewModel.downloadModels()
                        } label: {
                            Label("Download AI Voices", systemImage: "arrow.down.circle.fill")
                                .font(.callout.weight(.semibold))
                                .frame(maxWidth: 260)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppConstants.accent)
                        .controlSize(.large)

                        Text("~930 MB · On-device speech recognition & voice synthesis")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            viewModel.goNext()
                        } label: {
                            Label("Use Apple Voices Instead", systemImage: "apple.logo")
                                .font(.callout)
                                .frame(maxWidth: 260)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Text("No download · Uses built-in macOS speech")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Language picker (always visible)
                if viewModel.isModelReady || viewModel.isModelDownloading {
                    VStack(spacing: 8) {
                        Picker("Language", selection: $viewModel.selectedLangCode) {
                            ForEach(sortedLangCodes, id: \.code) { lang in
                                Text(lang.name).tag(lang.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 240)

                        Text("You can change the voice in Settings later.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        // Dep install section for Japanese/Chinese
                        if viewModel.needsLangDeps && !viewModel.langDepsReady {
                            VStack(spacing: 8) {
                                if viewModel.depsInstaller.isInstalling {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                        Text(viewModel.depsInstaller.installProgress)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                } else {
                                    let langName = KokoroVoiceCatalog.languageNames[viewModel.selectedLangCode] ?? "This language"
                                    let sizeHint = viewModel.selectedLangCode == "j" ? " (~500 MB)" : " (~45 MB)"
                                    Text("\(langName) requires additional dependencies\(sizeHint).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Button("Install Dependencies") {
                                        viewModel.installLangDeps()
                                    }
                                    .buttonStyle(.bordered)

                                    if let error = viewModel.depsInstaller.installError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding(14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 48)
                        }
                    }
                }

                Spacer()
            }

            if viewModel.isModelReady || viewModel.isModelDownloading {
                OnboardingFooter(
                    primaryLabel: viewModel.isModelReady ? "Continue" : "Skip",
                    primaryAction: { viewModel.goNext() }
                )
            }
        }
        .padding(.horizontal, 48)
    }
}
