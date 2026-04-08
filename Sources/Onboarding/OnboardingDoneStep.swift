import SwiftUI
import AppKit

struct OnboardingDoneStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingSplashShell(
            eyebrow: "Ready",
            title: "You're all set.",
            subtitle: "Lives in your menu bar. Beeps when Claude needs you.\nRestart any running Claude Code sessions for hooks to take effect.",
            titleIsHero: false,
            isDark: false,
            showBack: true,
            onBack: { viewModel.goBack() },
            primaryLabel: "Launch CC-Beeper",
            primaryAction: handleLaunch
        ) {
            CheckDisc()
        }
    }

    private func handleLaunch() {
        viewModel.completeOnboarding()
        for window in NSApp.windows {
            if window.identifier?.rawValue == "main" {
                window.makeKeyAndOrderFront(nil)
            }
            if window.identifier?.rawValue == "onboarding" {
                window.orderOut(nil)
            }
        }
    }
}

// MARK: - Green check disc

private struct CheckDisc: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(OnboardingTheme.green)
                .frame(width: 52, height: 52)
                .shadow(color: OnboardingTheme.green.opacity(0.3), radius: 8, x: 0, y: 4)
            Image(systemName: "checkmark")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(OnboardingTheme.ivory)
        }
    }
}
