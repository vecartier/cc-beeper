import SwiftUI

struct OnboardingWelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingSplashShell(
            eyebrow: "",
            title: "CC-Beeper",
            subtitle: "A floating macOS pager for Claude Code.\nNever miss an update. Respond without breaking your flow.",
            titleIsHero: true,
            isDark: true,
            showBack: false,
            onBack: {},
            primaryLabel: "Get Started",
            primaryAction: { viewModel.goNext() }
        ) {
            appIcon
        }
    }

    // MARK: Lead icon

    private var appIcon: some View {
        Group {
            if let nsImage = Self.loadAppIcon() {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [OnboardingTheme.terracotta, OnboardingTheme.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(OnboardingTheme.ivory)
                    )
            }
        }
    }

    private static func loadAppIcon() -> NSImage? {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let image = NSImage(contentsOfFile: iconPath) {
            return image
        }
        if let resourcePath = Bundle.main.resourcePath,
           let image = NSImage(contentsOfFile: resourcePath + "/../../../icon.png") {
            return image
        }
        return nil
    }
}
