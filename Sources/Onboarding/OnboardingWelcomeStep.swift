import SwiftUI

struct OnboardingWelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()

                // App icon with macOS squircle mask
                if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
                   let nsImage = NSImage(contentsOfFile: iconPath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                } else if let iconPath = (Bundle.main.resourcePath.map { $0 + "/../../../icon.png" }),
                          let nsImage = NSImage(contentsOfFile: iconPath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

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
            }
            .padding(.horizontal, 48)

            OnboardingFooter(
                primaryLabel: "Get Started",
                primaryAction: { viewModel.goNext() }
            )
        }
    }
}
