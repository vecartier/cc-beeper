import SwiftUI

struct OnboardingWelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Cover image
            if let coverPath = Bundle.main.path(forResource: "cover", ofType: "png"),
               let nsImage = NSImage(contentsOfFile: coverPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            }

            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Welcome to CC-Beeper")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Your desktop companion for Claude Code.\nSee what Claude is doing, respond to permissions,\nand talk to it — without leaving your workflow.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                Spacer()

                Button {
                    viewModel.goNext()
                } label: {
                    Text("Get Started")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: 240)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 48)
        }
    }
}
