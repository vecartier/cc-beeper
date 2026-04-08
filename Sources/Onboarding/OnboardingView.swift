import SwiftUI
import AppKit

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    private var isDarkStep: Bool { viewModel.currentStep == .welcome }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar — hidden on welcome splash
            if viewModel.currentStep != .welcome {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(OnboardingTheme.borderCream)
                        Rectangle()
                            .fill(OnboardingTheme.terracotta)
                            .frame(width: geo.size.width * viewModel.displayProgress)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.displayProgress)
                    }
                }
                .frame(height: 3)
            } else {
                Color.clear.frame(height: 3)
            }

            // Step content
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    OnboardingWelcomeStep(viewModel: viewModel)
                case .cliAndHooks:
                    OnboardingCLIStep(viewModel: viewModel)
                case .theme:
                    OnboardingThemeStep(viewModel: viewModel)
                case .sizes:
                    OnboardingSizesStep(viewModel: viewModel)
                case .mode:
                    OnboardingModeStep(viewModel: viewModel)
                case .permissions:
                    OnboardingPermissionsStep(viewModel: viewModel)
                case .stt:
                    OnboardingSTTStep(viewModel: viewModel)
                case .tts:
                    OnboardingTTSStep(viewModel: viewModel)
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
        .background(isDarkStep ? OnboardingTheme.nearBlack : OnboardingTheme.parchment)
        .foregroundStyle(isDarkStep ? OnboardingTheme.ivory : OnboardingTheme.nearBlack)
        .animation(.easeInOut(duration: 0.25), value: isDarkStep)
        .onAppear {
            if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" })?.orderOut(nil)
            }
        }
    }
}
