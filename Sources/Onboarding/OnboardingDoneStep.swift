import SwiftUI
import AppKit

struct OnboardingDoneStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                VStack(spacing: 10) {
                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("CC-Beeper will appear in your menu bar and react to Claude's activity in real time.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 32)
                }

                // Important note
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text("Restart any running Claude Code sessions for hooks to take effect.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 48)

                Spacer()
            }

            Button {
                viewModel.completeOnboarding()
                for window in NSApp.windows {
                    if window.identifier?.rawValue == "main" {
                        window.makeKeyAndOrderFront(nil)
                    }
                    if window.identifier?.rawValue == "onboarding" {
                        window.orderOut(nil)
                    }
                }
            } label: {
                Text("Launch CC-Beeper")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: 240)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 36)
        }
    }
}
