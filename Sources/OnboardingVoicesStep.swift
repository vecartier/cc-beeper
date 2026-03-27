import SwiftUI

// This step has been merged into OnboardingModelDownloadStep.
// Kept as a redirect in case any references remain.
struct OnboardingVoicesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingModelDownloadStep(viewModel: viewModel)
    }
}
