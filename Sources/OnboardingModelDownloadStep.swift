import SwiftUI

struct OnboardingModelDownloadStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)

                VStack(spacing: 14) {
                    Text("Voice Setup")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Choose how CC-Beeper handles voice input and spoken summaries.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }

                if viewModel.isModelReady {
                    Label("AI Models Ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3.weight(.semibold))
                        .padding(.top, 8)

                } else if viewModel.isModelDownloading {
                    VStack(spacing: 10) {
                        ProgressView(value: viewModel.modelDownloadProgress)
                            .progressViewStyle(.linear)
                            .tint(.orange)
                            .padding(.horizontal, 32)

                        Text(viewModel.modelDownloadPhase)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                } else {
                    VStack(spacing: 14) {
                        Button {
                            viewModel.downloadModels()
                        } label: {
                            Label("Download AI Voices", systemImage: "arrow.down.circle.fill")
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.large)

                        Text("~930 MB · On-device AI for speech recognition & voice synthesis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            viewModel.goNext()
                        } label: {
                            Label("Use Apple Voices Instead", systemImage: "apple.logo")
                                .font(.callout)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.top, 4)

                        Text("No download needed · Uses built-in macOS speech")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)

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
                HStack(spacing: 16) {
                    if viewModel.isModelDownloading {
                        Button("Skip") {
                            viewModel.goNext()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    if viewModel.isModelReady {
                        Button {
                            viewModel.goNext()
                        } label: {
                            Text("Continue")
                                .font(.title3.weight(.semibold))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.large)
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .padding(.horizontal, 32)
    }
}
