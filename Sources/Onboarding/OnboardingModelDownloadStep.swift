import SwiftUI

struct OnboardingModelDownloadStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

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

                if viewModel.isModelReady {
                    Label("AI Models Ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3.weight(.semibold))
                        .padding(.top, 8)

                } else if viewModel.isModelDownloading {
                    VStack(spacing: 12) {
                        ProgressView(value: viewModel.modelDownloadProgress)
                            .progressViewStyle(.linear)
                            .tint(.orange)
                            .padding(.horizontal, 48)

                        Text(viewModel.modelDownloadPhase)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                } else {
                    VStack(spacing: 16) {
                        Button {
                            viewModel.downloadModels()
                        } label: {
                            Label("Download AI Voices", systemImage: "arrow.down.circle.fill")
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: 280)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.large)

                        Text("~930 MB · On-device speech recognition & voice synthesis")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            viewModel.goNext()
                        } label: {
                            Label("Use Apple Voices Instead", systemImage: "apple.logo")
                                .font(.callout)
                                .frame(maxWidth: 280)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Text("No download · Uses built-in macOS speech")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if !viewModel.modelDownloadPhase.isEmpty {
                        Text(viewModel.modelDownloadPhase)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.top, 4)
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
