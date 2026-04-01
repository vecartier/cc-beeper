import SwiftUI
import AppKit

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                    Rectangle()
                        .fill(AppConstants.accent)
                        .frame(width: geo.size.width * viewModel.progress)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 3)

            // Step content
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    OnboardingWelcomeStep(viewModel: viewModel)
                case .cliAndHooks:
                    OnboardingCLIStep(viewModel: viewModel)
                case .theme:
                    OnboardingThemeStep(viewModel: viewModel)
                case .mode:
                    OnboardingModeStep(viewModel: viewModel)
                case .permissions:
                    OnboardingPermissionsStep(viewModel: viewModel)
                case .voice:
                    OnboardingVoiceStep(viewModel: viewModel)
                case .hotkeys:
                    OnboardingHotkeysStep(viewModel: viewModel)
                case .done:
                    OnboardingDoneStep(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
        }
        .frame(width: 600, height: 520)
        .onAppear {
            if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" })?.orderOut(nil)
            }
        }
    }
}
