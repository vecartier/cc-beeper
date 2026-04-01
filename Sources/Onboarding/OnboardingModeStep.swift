import SwiftUI

struct OnboardingModeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let presets: [PermissionPreset] = [.cautious, .relaxed, .trusted, .yolo]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 8) {
                    Text("How do you like to work?")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("You can change this anytime from the menu bar.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        PresetCard(
                            preset: preset,
                            isSelected: viewModel.selectedPreset == preset,
                            onSelect: { viewModel.selectedPreset = preset }
                        )
                    }
                }
                .padding(.horizontal, 48)

                Spacer()
            }

            OnboardingFooter(
                primaryLabel: "Next",
                primaryAction: { viewModel.goNext() }
            )
        }
    }
}

private struct PresetCard: View {
    let preset: PermissionPreset
    let isSelected: Bool
    let onSelect: () -> Void

    private var detailedDescription: String {
        switch preset {
        case .cautious: "CC-Beeper asks before every tool use. Full control, more interruptions."
        case .relaxed: "Auto-approves reads (files, search). Asks before writes or shell commands."
        case .trusted: "Auto-approves all file operations. Only asks before running shell commands."
        case .yolo: "Claude runs freely with no permission prompts. Maximum speed, minimum friction."
        }
    }

    var body: some View {
        Button { onSelect() } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.label)
                    .fontWeight(.semibold)
                Text(detailedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? AppConstants.accent : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
