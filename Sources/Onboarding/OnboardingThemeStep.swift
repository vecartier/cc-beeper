import SwiftUI

struct OnboardingThemeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedTheme: ShellTheme {
        ThemeManager.themes.first { $0.id == viewModel.selectedThemeId } ?? ThemeManager.themes[0]
    }

    var body: some View {
        OnboardingShell(
            stepNumber: 2,
            totalSteps: OnboardingViewModel.totalCountedSteps,
            title: "Pick your Beeper color",
            subtitle: "Sets the vibe. Easy to swap later.",
            primaryLabel: "Next",
            primaryAction: { viewModel.goNext() },
            skipLabel: nil,
            skipAction: nil,
            onBack: { viewModel.goBack() }
        ) {
            VStack(spacing: 20) {
                // Always show the large (button-equipped) beeper — colour is what this step is about.
                LargeShellPreview(theme: selectedTheme)
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
                                    .frame(width: 24, height: 24)
                                if theme.id == "white" {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                        .frame(width: 24, height: 24)
                                }
                                if viewModel.selectedThemeId == theme.id {
                                    Circle()
                                        .strokeBorder(OnboardingTheme.terracotta, lineWidth: 2)
                                        .frame(width: 30, height: 30)
                                }
                            }
                            .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(selectedTheme.displayName.uppercased())
                    .font(OnboardingTheme.mono(10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(OnboardingTheme.nearBlack)
                    .animation(.none, value: viewModel.selectedThemeId)
            }
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

            HStack(spacing: 3) {
                Circle().fill(AppConstants.ledGreen).frame(width: 4, height: 4)
                    .shadow(color: AppConstants.ledGreen.opacity(0.6), radius: 2)
                Circle().fill(AppConstants.ledOff).frame(width: 4, height: 4)
            }
            .offset(x: 226, y: 15)

            OnboardingLCD(animFrame: animFrame)
                .frame(width: lcdW, height: lcdH)
                .clipped()
                .offset(x: lcdX, y: lcdY)

            // Button overlays (static, decorative)
            OnboardingButtonRow()
                .offset(x: 12, y: shellH - 54)
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

    private let shellW: CGFloat = 160
    private let shellH: CGFloat = 82
    private let lcdX: CGFloat = 24
    private let lcdY: CGFloat = 24
    private let lcdW: CGFloat = 105
    private let lcdH: CGFloat = 23

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
            .offset(x: 125, y: 15)

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
        VStack(spacing: 8) {
            Image(nsImage: BeeperIcon.image(state: .normal))
                .frame(width: 32, height: 32)
                .scaleEffect(1.8)

            Text("Lives in your menu bar")
                .font(OnboardingTheme.sans(11))
                .foregroundStyle(OnboardingTheme.stone)
        }
        .frame(height: 102)
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
                    .frame(width: compact ? 22 : 26, height: compact ? 20 : 22)

                VStack(alignment: .leading, spacing: 1) {
                    Text("SNOOZING")
                        .font(.system(size: compact ? 8 : 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(lcdOn)
                    Text("Idle")
                        .font(.system(size: compact ? 6 : 7, weight: .medium, design: .monospaced))
                        .foregroundColor(lcdOn.opacity(0.7))
                }

                Spacer()
            }
            .padding(.leading, compact ? 8 : 10)

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

// MARK: - Decorative button row
//
// Production constants: pill 122×68, button 78×68, HStack spacing -16/-24.
// `productionScale` maps to fraction of production size:
//   0.75 → Theme preview (270×120 shell)
//   0.5  → Sizes cards  (183×80 shell)

struct OnboardingButtonRow: View {
    var productionScale: CGFloat = 0.75

    private var pillW: CGFloat { 122 * productionScale }
    private var pillH: CGFloat { 68 * productionScale }
    private var btnW: CGFloat { 78 * productionScale }
    private var btnH: CGFloat { 68 * productionScale }
    private var outerSpacing: CGFloat { -16 * productionScale }
    private var innerSpacing: CGFloat { -24 * productionScale }

    var body: some View {
        HStack(alignment: .center, spacing: outerSpacing) {
            img("pill-normal.png", width: pillW, height: pillH)
            HStack(spacing: innerSpacing) {
                img("record-normal.png", width: btnW, height: btnH)
                img("sound-normal.png", width: btnW, height: btnH)
            }
            img("terminal-normal.png", width: btnW, height: btnH)
        }
        .allowsHitTesting(false)
    }

    private func img(_ name: String, width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let nsImg = loadImage(name) {
                Image(nsImage: nsImg)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: width, height: height)
            }
        }
    }
}

private func loadImage(_ name: String) -> NSImage? {
    guard let path = Bundle.main.resourcePath else { return nil }
    return NSImage(contentsOfFile: path + "/" + name)
}
