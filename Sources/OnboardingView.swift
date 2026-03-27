import SwiftUI
import AppKit

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Thin progress bar at very top
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .frame(height: 4)
                .tint(.orange)

            // Step content
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    OnboardingWelcomeStep(viewModel: viewModel)
                case .cliAndHooks:
                    OnboardingCLIStep(viewModel: viewModel)
                case .permissions:
                    OnboardingPermissionsStep(viewModel: viewModel)
                case .modelDownload:
                    OnboardingModelDownloadStep(viewModel: viewModel)
                case .done:
                    OnboardingDoneStep(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
        }
        .frame(width: 480, height: 400)
        .onAppear {
            // Belt-and-suspenders: close if already onboarded (prevents state restoration re-open)
            if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" })?.orderOut(nil)
            }
        }
    }
}
