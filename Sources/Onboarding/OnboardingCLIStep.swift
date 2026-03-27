import SwiftUI

struct OnboardingCLIStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "terminal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)

                Text("Claude Code Setup")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    // Claude CLI detection row
                    SetupRow(
                        icon: viewModel.isClaudeDetected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                        iconColor: viewModel.isClaudeDetected ? .green : .orange,
                        title: "Claude Code CLI",
                        subtitle: viewModel.isClaudeDetected ? "Detected" : nil,
                        link: viewModel.isClaudeDetected ? nil : ("Install Claude Code", URL(string: "https://docs.anthropic.com/en/docs/claude-code/overview")!)
                    )

                    // Hooks installation row
                    SetupRow(
                        icon: viewModel.isHooksInstalled ? "checkmark.circle.fill" : "circle",
                        iconColor: viewModel.isHooksInstalled ? .green : .secondary,
                        title: "Hooks",
                        subtitle: viewModel.isHooksInstalled ? "Installed" : (viewModel.isClaudeDetected ? "Not installed" : "Requires Claude Code"),
                        action: (!viewModel.isHooksInstalled && viewModel.isClaudeDetected) ? ("Install Hooks", { viewModel.installHooks() }) : nil
                    )
                }
                .padding(.horizontal, 48)

                if let error = viewModel.hookInstallError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 48)
                }

                Spacer()
            }

            OnboardingFooter(
                primaryLabel: "Next",
                primaryAction: { viewModel.goNext() },
                primaryDisabled: !viewModel.isClaudeDetected,
                showSkip: true,
                skipAction: { viewModel.goNext() }
            )
        }
        .onAppear {
            viewModel.detectClaude()
        }
    }
}

// MARK: - Reusable Components

struct SetupRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var link: (String, URL)? = nil
    var action: (String, () -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title2)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.medium)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let link {
                    Link(link.0, destination: link.1)
                        .font(.caption)
                }
            }

            Spacer()

            if let action {
                Button(action.0) { action.1() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct OnboardingFooter: View {
    let primaryLabel: String
    let primaryAction: () -> Void
    var primaryDisabled: Bool = false
    var showSkip: Bool = false
    var skipAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Button {
                primaryAction()
            } label: {
                Text(primaryLabel)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: 240)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)
            .disabled(primaryDisabled)

            if showSkip, let skipAction {
                Button("Skip") { skipAction() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 32)
    }
}
