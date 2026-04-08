import SwiftUI

// Production shell dimensions: Large 366×160, Compact 220×113.
// Sizes step renders at 0.5× production for 3-across layout.

struct OnboardingSizesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var themeId: String {
        viewModel.selectedThemeId.isEmpty ? "black" : viewModel.selectedThemeId
    }

    private var theme: ShellTheme {
        ThemeManager.themes.first { $0.id == themeId } ?? ThemeManager.themes[0]
    }

    var body: some View {
        OnboardingShell(
            stepNumber: 3,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "How visible should it be?",
            subtitle: "You can always change this from the menu bar.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            skipLabel: nil,
            skipAction: nil,
            onBack: { viewModel.goBack() }
        ) {
            HStack(alignment: .bottom, spacing: 20) {
                // LARGE — 183×80 (0.5× of 366×160), with buttons
                SizeOption(isSelected: viewModel.selectedSize == .large,
                           label: "Large", desc: "Buttons + LCD",
                           onTap: { viewModel.selectedSize = .large }) {
                    ZStack(alignment: .topLeading) {
                        if let img = loadSizeImage(theme.shellImage) {
                            Image(nsImage: img)
                                .resizable()
                                .interpolation(.high)
                                .frame(width: 183, height: 80)
                        }
                        OnboardingButtonRow(productionScale: 0.5)
                            .offset(x: 8, y: 44)
                    }
                    .frame(width: 183, height: 80)
                }

                // COMPACT — 110×57 (0.5× of 220×113), no buttons
                SizeOption(isSelected: viewModel.selectedSize == .compact,
                           label: "Compact", desc: "LCD only",
                           onTap: { viewModel.selectedSize = .compact }) {
                    if let img = loadSizeImage("beeper-small-\(themeId).png") {
                        Image(nsImage: img)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 110, height: 57)
                    }
                }

                // MENU ONLY — tiny icon
                SizeOption(isSelected: viewModel.selectedSize == .menuOnly,
                           label: "Menu only", desc: "Icon only",
                           onTap: { viewModel.selectedSize = .menuOnly }) {
                    Image(nsImage: BeeperIcon.image(state: .normal))
                        .frame(width: 24, height: 24)
                        .scaleEffect(1.5)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: viewModel.selectedSize)
        }
    }

    private func loadSizeImage(_ name: String) -> NSImage? {
        guard let path = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: path + "/" + name)
    }
}

// MARK: - Size option card

private struct SizeOption<Preview: View>: View {
    let isSelected: Bool
    let label: String
    let desc: String
    let onTap: () -> Void
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                preview()
                    .frame(height: 80)

                VStack(spacing: 3) {
                    Text(label.uppercased())
                        .font(OnboardingTheme.mono(10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(OnboardingTheme.nearBlack)
                    Text(desc)
                        .font(OnboardingTheme.sans(10))
                        .foregroundStyle(OnboardingTheme.stone)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusMedium, style: .continuous)
                    .fill(isSelected ? Color(hex: "FBF7F4") : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingTheme.radiusMedium, style: .continuous)
                    .strokeBorder(isSelected ? OnboardingTheme.terracotta : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
