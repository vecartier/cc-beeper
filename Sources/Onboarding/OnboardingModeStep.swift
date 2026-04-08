import SwiftUI

struct OnboardingModeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let presets: [PermissionPreset] = [.cautious, .relaxed, .trusted, .yolo]
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        OnboardingShell(
            stepNumber: 4,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Auto-accept permissions",
            subtitle: "When Claude Code needs to use a tool, CC-Beeper can auto-approve or ask you first. Change anytime in the menu bar.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            skipLabel: nil,
            skipAction: nil,
            onBack: { viewModel.goBack() }
        ) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    PresetCard(
                        preset: preset,
                        isSelected: viewModel.selectedPreset == preset,
                        onSelect: { viewModel.selectedPreset = preset }
                    )
                }
            }
            .frame(maxWidth: 460)
            .animation(.easeInOut(duration: 0.15), value: viewModel.selectedPreset)
        }
    }
}

private struct PresetCard: View {
    let preset: PermissionPreset
    let isSelected: Bool
    let onSelect: () -> Void

    private var shortDescription: String {
        switch preset {
        case .cautious: "Approve every tool call."
        case .relaxed: "Auto-approve reads only."
        case .trusted: "Auto-approve file ops."
        case .yolo: "Auto-approve everything."
        }
    }

    private var accentColor: Color {
        switch preset {
        case .cautious: return OnboardingTheme.green
        case .relaxed: return OnboardingTheme.stone
        case .trusted: return OnboardingTheme.amber
        case .yolo: return OnboardingTheme.crimson
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: preset.badgeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.label.uppercased())
                        .font(OnboardingTheme.mono(11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(OnboardingTheme.nearBlack)
                    Text(shortDescription)
                        .font(OnboardingTheme.sans(11))
                        .foregroundStyle(OnboardingTheme.stone)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusMedium, style: .continuous)
                    .fill(isSelected ? Color(hex: "FBF7F4") : OnboardingTheme.ivory)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusMedium, style: .continuous)
                    .strokeBorder(isSelected ? OnboardingTheme.terracotta : OnboardingTheme.borderCream, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
