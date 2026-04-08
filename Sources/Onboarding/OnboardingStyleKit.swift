import SwiftUI

// MARK: - Onboarding Style Kit
//
// Reusable UI primitives extracted from the launch video's visual vocabulary
// (LaunchVideo.jsx). These give every onboarding step a consistent rhythm:
//
//   EYEBROW LABEL          (mono caps, stone, tracked)
//   Editorial headline     (serif medium, nearBlack)
//   Supporting caption.    (sans regular, stone)
//
// Primitives compose — drop them into any step without rewriting layout.

// MARK: Eyebrow label

/// Small uppercase mono label, letter-spaced, warm stone gray.
/// Used as a section tag above a headline, e.g. "EIGHT STATES".
struct OnboardingEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(OnboardingTheme.mono(10, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(OnboardingTheme.stone)
    }
}

// MARK: Headline

/// Editorial serif headline, warm near-black. One or two lines max.
struct OnboardingHeadline: View {
    let text: String
    var size: CGFloat = 22

    var body: some View {
        Text(text)
            .font(OnboardingTheme.serif(size, weight: .medium))
            .foregroundStyle(OnboardingTheme.nearBlack)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

// MARK: Caption

/// Sub-headline caption in warm stone gray. Short, supporting copy only.
struct OnboardingCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(OnboardingTheme.sans(13))
            .foregroundStyle(OnboardingTheme.stone)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
    }
}

// MARK: Section header — composes the three above

/// Label + headline + optional caption, centered stack with the video's spacing.
struct OnboardingSectionHeader: View {
    let eyebrow: String
    let headline: String
    var caption: String? = nil
    var headlineSize: CGFloat = 22

    var body: some View {
        VStack(spacing: 10) {
            OnboardingEyebrow(text: eyebrow)
            OnboardingHeadline(text: headline, size: headlineSize)
                .padding(.top, -2)
            if let caption {
                OnboardingCaption(text: caption)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: Pill button (primary)

/// Terracotta primary CTA — matches the shape/feel of the video's action buttons.
/// Press state darkens and scales slightly.
struct OnboardingPillButton: View {
    let title: String
    let action: () -> Void
    var minWidth: CGFloat = 180
    var disabled: Bool = false

    @State private var isPressed: Bool = false

    private var fillColor: Color {
        if disabled { return OnboardingTheme.warmSilver }
        return isPressed ? OnboardingTheme.coral : OnboardingTheme.terracotta
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingTheme.sans(14, weight: .semibold))
                .foregroundStyle(OnboardingTheme.ivory)
                .frame(minWidth: minWidth)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(fillColor)
                )
                .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !disabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: Pill button (secondary / ghost)

/// Ivory ghost button with warm hairline border — for secondary actions.
struct OnboardingGhostButton: View {
    let title: String
    let action: () -> Void
    var minWidth: CGFloat = 120

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingTheme.sans(14, weight: .medium))
                .foregroundStyle(OnboardingTheme.nearBlack)
                .frame(minWidth: minWidth)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(isPressed ? OnboardingTheme.borderCream : OnboardingTheme.ivory)
                )
                .overlay(
                    Capsule().strokeBorder(OnboardingTheme.ringWarm, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: Keycap (for hotkeys, shortcuts)

/// Ivory keycap with warm ring — matches the video's hotkey row styling.
struct OnboardingKeycap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(OnboardingTheme.mono(13, weight: .semibold))
            .foregroundStyle(OnboardingTheme.nearBlack)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusSmall, style: .continuous)
                    .fill(OnboardingTheme.ivory)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusSmall, style: .continuous)
                    .strokeBorder(OnboardingTheme.ringWarm, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview("Style Kit") {
    VStack(spacing: 40) {
        OnboardingSectionHeader(
            eyebrow: "Eight States",
            headline: "At a glance, know exactly what Claude is up to.",
            caption: "Never miss an update. Respond without breaking your flow."
        )

        HStack(spacing: 8) {
            OnboardingKeycap(text: "⌘⇧A")
            OnboardingKeycap(text: "⌘⇧D")
            OnboardingKeycap(text: "⌘⇧M")
        }

        HStack(spacing: 12) {
            OnboardingGhostButton(title: "Skip", action: {})
            OnboardingPillButton(title: "Get Started", action: {})
        }
    }
    .padding(48)
    .frame(width: 600, height: 440)
    .background(OnboardingTheme.parchment)
}

// MARK: - Onboarding card style (selectable cards for engine pickers)

private struct OnboardingCardStyleModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusMedium, style: .continuous)
                    .fill(isSelected ? Color(hex: "FBF7F4") : OnboardingTheme.ivory)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusMedium, style: .continuous)
                    .strokeBorder(isSelected ? OnboardingTheme.terracotta : OnboardingTheme.borderCream, lineWidth: isSelected ? 1.5 : 1)
            )
    }
}

extension View {
    func onboardingCardStyle(isSelected: Bool) -> some View {
        modifier(OnboardingCardStyleModifier(isSelected: isSelected))
    }
}
