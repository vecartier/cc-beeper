import SwiftUI

struct OnboardingThemeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedTheme: ShellTheme {
        ThemeManager.themes.first { $0.id == viewModel.selectedThemeId } ?? ThemeManager.themes[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Spacer()

                VStack(spacing: 4) {
                    Text("Pick your Beeper")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Every dev gets their own Beeper. Pick yours.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                // Live beeper preview
                Group {
                    switch viewModel.selectedSize {
                    case .large:
                        LargeShellPreview(theme: selectedTheme)
                    case .compact:
                        CompactShellPreview(theme: selectedTheme)
                    case .menuOnly:
                        MenuOnlyPreview()
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.selectedSize)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedThemeId)

                // Color swatches
                HStack(spacing: 10) {
                    ForEach(ThemeManager.themes) { theme in
                        Button {
                            viewModel.selectedThemeId = theme.id
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: theme.dotColor))
                                    .frame(width: 26, height: 26)
                                if theme.id == "white" {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                        .frame(width: 26, height: 26)
                                }
                                if viewModel.selectedThemeId == theme.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(theme.id == "white" ? .black : .white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(selectedTheme.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .animation(.none, value: viewModel.selectedThemeId)

                // Size toggle
                VStack(spacing: 6) {
                    Picker("Size", selection: $viewModel.selectedSize) {
                        ForEach(WidgetSize.allCases, id: \.self) { size in
                            Text(size.label).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)

                    Text(viewModel.selectedSize.menuDescription)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 48)

            OnboardingFooter(
                primaryLabel: "Next",
                primaryAction: { viewModel.goNext() }
            )
        }
    }
}

// MARK: - Large Shell Preview

private struct LargeShellPreview: View {
    let theme: ShellTheme
    @State private var animFrame = 0
    private let animTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private let shellW: CGFloat = 270
    private let shellH: CGFloat = 120
    private let lcdX: CGFloat = 30
    private let lcdY: CGFloat = 25
    private let lcdW: CGFloat = 214
    private let lcdH: CGFloat = 34

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let img = loadImage(theme.shellImage) {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: shellW, height: shellH)
            }

            // LEDs
            HStack(spacing: 3) {
                Circle().fill(AppConstants.ledGreen).frame(width: 4, height: 4)
                    .shadow(color: AppConstants.ledGreen.opacity(0.6), radius: 2)
                Circle().fill(AppConstants.ledOff).frame(width: 4, height: 4)
            }
            .offset(x: 226, y: 15)

            // LCD with real pixel character
            OnboardingLCD(animFrame: animFrame)
                .frame(width: lcdW, height: lcdH)
                .clipped()
                .offset(x: lcdX, y: lcdY)
        }
        .frame(width: shellW, height: shellH)
        .onReceive(animTimer) { _ in animFrame += 1 }
    }
}

// MARK: - Compact Shell Preview

private struct CompactShellPreview: View {
    let theme: ShellTheme
    @State private var animFrame = 0
    private let animTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private let shellW: CGFloat = 180
    private let shellH: CGFloat = 92
    private let lcdX: CGFloat = 27
    private let lcdY: CGFloat = 27
    private let lcdW: CGFloat = 118
    private let lcdH: CGFloat = 26

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let img = loadImage("beeper-small-\(theme.id).png") {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: shellW, height: shellH)
            }

            HStack(spacing: 2) {
                Circle().fill(AppConstants.ledGreen).frame(width: 3, height: 3)
                Circle().fill(AppConstants.ledOff).frame(width: 3, height: 3)
            }
            .offset(x: 141, y: 17)

            OnboardingLCD(animFrame: animFrame, compact: true)
                .frame(width: lcdW, height: lcdH)
                .clipped()
                .offset(x: lcdX, y: lcdY)
        }
        .frame(width: shellW, height: shellH)
        .onReceive(animTimer) { _ in animFrame += 1 }
    }
}

// MARK: - Menu Only Preview

private struct MenuOnlyPreview: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: BeeperIcon.image(state: .normal))
                .frame(width: 36, height: 36)
                .scaleEffect(2)

            Text("Lives in your menu bar")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 120)
    }
}

// MARK: - LCD with Real Pixel Character

private struct OnboardingLCD: View {
    let animFrame: Int
    var compact: Bool = false

    private let lcdBg = Color(hex: "98D65A")
    private let lcdOn = Color(hex: "2A4A10")

    var body: some View {
        ZStack {
            lcdBg

            HStack(spacing: compact ? 4 : 6) {
                PixelCharacterView(state: .idle, frame: animFrame, onColor: lcdOn)
                    .frame(width: compact ? 24 : 28, height: compact ? 22 : 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text("SNOOZING")
                        .font(.system(size: compact ? 9 : 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(lcdOn)
                    Text("Idle")
                        .font(.system(size: compact ? 6 : 7, weight: .medium, design: .monospaced))
                        .foregroundColor(lcdOn.opacity(0.7))
                }

                Spacer()
            }
            .padding(.leading, compact ? 8 : 10)

            // Pixel grid
            Canvas { context, size in
                let lineColor = AppConstants.lcdGridLine.opacity(0.12)
                let spacing: CGFloat = 2.0
                var x: CGFloat = spacing
                while x < size.width {
                    context.fill(Path(CGRect(x: x, y: 0, width: 0.5, height: size.height)), with: .color(lineColor))
                    x += spacing
                }
                var y: CGFloat = spacing
                while y < size.height {
                    context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 0.5)), with: .color(lineColor))
                    y += spacing
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private func loadImage(_ name: String) -> NSImage? {
    guard let path = Bundle.main.resourcePath else { return nil }
    return NSImage(contentsOfFile: path + "/" + name)
}
