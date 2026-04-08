import SwiftUI

// MARK: - Onboarding Shells
//
// Two window-scoped scaffolds that wrap step content with consistent chrome:
//
//   OnboardingShell        — counted steps (01/07 eyebrow, back chevron, skip+primary CTA)
//   OnboardingSplashShell  — welcome/done splashes (lead icon, no step counter, primary-only CTA)
//
// The progress bar is rendered by OnboardingView at the window level, so it's
// not the shell's responsibility.

// MARK: - Back chevron

struct OnboardingBackChevron: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(OnboardingTheme.stone)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Skip button

struct OnboardingSkipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingTheme.sans(13, weight: .medium))
                .foregroundStyle(OnboardingTheme.stone)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - OnboardingShell (counted steps)

/// Shell for counted onboarding steps. Handles back chevron, step-counter eyebrow,
/// title/subtitle, body content, and skip+primary CTA buttons.
struct OnboardingShell<Content: View>: View {
    let stepNumber: Int
    let totalSteps: Int
    let title: String
    let subtitle: String?
    let primaryLabel: String
    let primaryAction: () -> Void
    var primaryDisabled: Bool = false
    let skipLabel: String?
    let skipAction: (() -> Void)?
    let onBack: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Top chrome — back chevron top-left
            HStack {
                OnboardingBackChevron(action: onBack)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 12)
            .frame(height: 44)

            // Title block
            VStack(spacing: 10) {
                Text(Self.stepLabel(number: stepNumber, total: totalSteps))
                    .font(OnboardingTheme.mono(10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(OnboardingTheme.stone)

                Text(title)
                    .font(OnboardingTheme.serif(24, weight: .medium))
                    .foregroundStyle(OnboardingTheme.nearBlack)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                if let subtitle {
                    Text(subtitle)
                        .font(OnboardingTheme.sans(13))
                        .foregroundStyle(OnboardingTheme.stone)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 440)
                }
            }
            .padding(.horizontal, 48)

            // Body content — top-aligned below title
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 32)
                .padding(.horizontal, 48)

            // CTA area
            HStack(spacing: 16) {
                if let skipLabel, let skipAction {
                    OnboardingSkipButton(title: skipLabel, action: skipAction)
                }
                OnboardingPillButton(title: primaryLabel, action: primaryAction,
                                     disabled: primaryDisabled)
            }
            .padding(.top, 24)
            .padding(.bottom, 56)
            .padding(.horizontal, 48)
        }
    }

    private static func stepLabel(number: Int, total: Int) -> String {
        String(format: "%02d / %02d", number, total)
    }
}

// MARK: - OnboardingSplashShell (welcome/done)

/// Shell for splash screens. Lead icon at the top, no step counter, primary-only CTA.
/// Supports dark mode for hero moments (welcome).
struct OnboardingSplashShell<LeadView: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    let titleIsHero: Bool
    let isDark: Bool
    let showBack: Bool
    let onBack: () -> Void
    let primaryLabel: String
    let primaryAction: () -> Void
    @ViewBuilder let leadIcon: () -> LeadView

    private var eyebrowColor: Color { isDark ? OnboardingTheme.warmSilver : OnboardingTheme.stone }
    private var headlineColor: Color { isDark ? OnboardingTheme.ivory : OnboardingTheme.nearBlack }
    private var captionColor: Color { isDark ? OnboardingTheme.warmSilver : OnboardingTheme.stone }

    var body: some View {
        VStack(spacing: 0) {
            // Top chrome
            HStack {
                if showBack {
                    OnboardingBackChevron(action: onBack)
                        .foregroundStyle(isDark ? OnboardingTheme.warmSilver : OnboardingTheme.stone)
                }
                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 12)
            .frame(height: 44)

            Spacer(minLength: 0)

            // Lead icon
            leadIcon()
                .padding(.bottom, 36)

            // Title block
            VStack(spacing: 10) {
                if !eyebrow.isEmpty {
                    Text(eyebrow.uppercased())
                        .font(OnboardingTheme.mono(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(eyebrowColor)
                }

                Text(title)
                    .font(titleIsHero
                          ? OnboardingTheme.serif(44, weight: .bold)
                          : OnboardingTheme.serif(24, weight: .medium))
                    .foregroundStyle(headlineColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                if let subtitle {
                    Text(subtitle)
                        .font(OnboardingTheme.sans(13))
                        .foregroundStyle(captionColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 440)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 48)

            Spacer(minLength: 24)

            OnboardingPillButton(title: primaryLabel, action: primaryAction)
                .padding(.bottom, 56)
        }
    }
}
