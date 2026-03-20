import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    private let shellW: CGFloat = 186
    private let shellH: CGFloat = 224

    @State private var showFeed = false

    var body: some View {
        VStack(spacing: 0) {
            // Existing Tamagotchi shell
            tamagotchiShell

            // Feed toggle button — small tab at bottom of shell
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showFeed.toggle() } }) {
                HStack(spacing: 3) {
                    Image(systemName: showFeed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 6, weight: .bold))
                    if !monitor.currentSessionActivities.isEmpty {
                        Text("\(monitor.currentSessionActivities.count)")
                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                    }
                }
                .foregroundStyle(themeManager.lcdOn.opacity(0.4))
                .frame(width: 40, height: 12)
                .background(
                    Capsule()
                        .fill(themeManager.lcdBg.opacity(0.6))
                )
            }
            .buttonStyle(.plain)
            .offset(y: -6)

            // Activity feed panel
            if showFeed {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.lcdBg)
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(themeManager.lcdOn.opacity(0.1), lineWidth: 0.5)

                    ActivityFeedView()
                }
                .frame(width: 200, height: 120)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: 250, height: showFeed ? 430 : 300)
        .background(Color.clear)
        .contextMenu {
            Button("Quit Claumagotchi") { NSApplication.shared.terminate(nil) }
        }
    }

    @ViewBuilder
    private var tamagotchiShell: some View {
        ZStack {
            // Diffused drop shadow
            Ellipse()
                .fill(.black.opacity(0.3))
                .frame(width: shellW + 10, height: shellH + 10)
                .blur(radius: 20)
                .offset(y: 6)

            // Main shell body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: themeManager.shellColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: shellW, height: shellH)

            // Noise texture overlay for plastic grain
            NoiseView()
                .frame(width: shellW, height: shellH)
                .clipShape(Ellipse())
                .opacity(0.08)
                .allowsHitTesting(false)

            // Top-left glossy highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.08),
                            .clear,
                        ],
                        center: UnitPoint(x: 0.3, y: 0.12),
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: shellW, height: shellH)

            // Rim bevel
            Ellipse()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(themeManager.darkMode ? 0.15 : 0.35),
                            .white.opacity(themeManager.darkMode ? 0.04 : 0.1),
                            .clear,
                            .black.opacity(0.12),
                            .black.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: shellW, height: shellH)

            // Content layout
            VStack(spacing: 4) {
                // Pixel title
                PixelTitle()
                    .frame(width: 160, height: 14)
                    .padding(.top, 18)
                    .padding(.bottom, 4)

                // Screen
                ZStack {
                    // LCD screen
                    ScreenView()
                        .frame(width: 116, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    // Inner shadow — crisp stroke
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.6),
                                    .black.opacity(0.15),
                                    .black.opacity(0.03),
                                    .black.opacity(0.08),
                                    .black.opacity(0.3),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 116, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .allowsHitTesting(false)

                    // Side inner shadow
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.2),
                                    .clear,
                                    .clear,
                                    .black.opacity(0.12),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 116, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .allowsHitTesting(false)
                    }

                Spacer().frame(height: 6)

                // Buttons — V-shaped layout (middle slightly lower)
                HStack(alignment: .top, spacing: 4) {
                    if monitor.autoAccept {
                        // YOLO mode: bolt (disable) + go-to-convo + mic
                        ActionButton(
                            symbol: "bolt.slash.fill", size: 12,
                            iconColor: .white,
                            active: true
                        ) { monitor.autoAccept = false }
                        .accessibilityLabel("Disable YOLO mode")

                        centerButton

                        micButton
                    } else {
                        // Normal mode: deny / center / allow / mic
                        ActionButton(
                            symbol: "xmark", size: 12,
                            iconColor: .white,
                            active: monitor.state.needsAttention
                        ) { monitor.respondToPermission(allow: false) }
                        .accessibilityLabel("Deny permission")

                        centerButton
                            .offset(y: 5)

                        ActionButton(
                            symbol: "checkmark", size: 12,
                            iconColor: .white,
                            active: monitor.state.needsAttention,
                            pulse: monitor.state.needsAttention
                        ) { monitor.respondToPermission(allow: true) }
                        .accessibilityLabel("Allow permission")

                        micButton
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: monitor.state)
                .animation(.easeInOut(duration: 0.3), value: monitor.autoAccept)
                .frame(height: 40)
                .offset(y: -8)
            }
        }
        .frame(width: 250, height: 300)
    }

    private var centerButton: some View {
        ActionButton(
            symbol: "arrow.up.forward", size: 12,
            iconColor: .white,
            active: monitor.state.canGoToConvo || monitor.state.needsAttention,
            pulse: monitor.state.canGoToConvo
        ) { monitor.goToConversation() }
        .accessibilityLabel("Go to conversation")
    }

    private var micButton: some View {
        ActionButton(
            symbol: monitor.voiceService.isRecording ? "mic.fill" : "mic",
            size: 12,
            iconColor: .white,
            active: monitor.voiceService.isRecording,
            pulse: monitor.voiceService.isRecording
        ) {
            if monitor.voiceService.isRecording {
                monitor.voiceService.stopRecording()
            } else {
                monitor.voiceService.startRecording()
            }
        }
        .accessibilityLabel(monitor.voiceService.isRecording ? "Stop recording" : "Start voice input")
    }
}

// MARK: - Noise Texture

struct NoiseView: View {
    // Render once, cache forever — noise is deterministic (seeded RNG)
    private static let cachedImage: NSImage = {
        let width = 186
        let height = 224
        let step: CGFloat = 1.5
        let img = NSImage(size: NSSize(width: width, height: height))
        img.lockFocus()
        var rng = SeededRNG(seed: 42)
        var y: CGFloat = 0
        while y < CGFloat(height) {
            var x: CGFloat = 0
            while x < CGFloat(width) {
                let val = rng.next()
                if val < 0.45 {
                    NSColor.white.withAlphaComponent(val * 0.7).setFill()
                    NSRect(x: x, y: y, width: step, height: step).fill()
                } else if val > 0.55 {
                    NSColor.black.withAlphaComponent((1.0 - val) * 0.5).setFill()
                    NSRect(x: x, y: y, width: step, height: step).fill()
                }
                x += step
            }
            y += step
        }
        img.unlockFocus()
        return img
    }()

    var body: some View {
        Image(nsImage: Self.cachedImage)
            .resizable()
    }
}

struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state &>> 1) / Double(UInt64.max >> 1)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let symbol: String
    var size: CGFloat = 9
    var iconColor: Color = .white
    let active: Bool
    var pulse: Bool = false
    var buttonSize: CGFloat = 28
    let action: () -> Void

    @State private var animating = false

    private var wellSize: CGFloat { buttonSize + 3 }
    private var frameSize: CGFloat { buttonSize + 4 }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Recessed well the button sits in
                Circle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: wellSize, height: wellSize)
                    .blur(radius: 1)

                // Button face — themed accent color
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.accentBase.opacity(active ? 0.5 : 0.3),
                                themeManager.accentDark.opacity(active ? 0.6 : 0.35),
                            ],
                            center: UnitPoint(x: 0.4, y: 0.35),
                            startRadius: 0,
                            endRadius: buttonSize * 0.57
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)

                // Top specular highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.05),
                                .clear,
                            ],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)

                // Bottom catch light
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.08),
                            ],
                            startPoint: .center, endPoint: .bottom
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)

                // Rim
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .clear,
                                .black.opacity(0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .frame(width: buttonSize, height: buttonSize)

                Image(systemName: symbol)
                    .font(.system(size: size, weight: .black))
                    .foregroundColor(active ? iconColor : Color(hex: "A8A4A0"))
                    .shadow(color: .black.opacity(active ? 0.3 : 0), radius: 0.5, y: 0.5)
            }
            .frame(width: frameSize, height: frameSize)
            .scaleEffect(pulse && animating ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!active)
        .onChange(of: pulse) {
            if pulse {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    animating = true
                }
            } else {
                withAnimation(.none) { animating = false }
            }
        }
    }
}

// MARK: - Pixel Title

struct PixelTitle: View {
    @EnvironmentObject var themeManager: ThemeManager

    private let px: CGFloat = 1.4
    private let gap: CGFloat = 1.0

    // Rounded, playful letterforms — inspired by Tamagotchi logo
    private static let font: [Character: [String]] = [
        "C": [".###.", "#...#", "#....", "#....", "#...#", ".###."],
        "L": ["#....", "#....", "#....", "#....", "#....", "#####"],
        "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#"],
        "U": ["#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
        "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#"],
        "G": [".###.", "#....", "#.###", "#...#", "#...#", ".###."],
        "O": [".###.", "#...#", "#...#", "#...#", "#...#", ".###."],
        "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#.."],
        "H": ["#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
        "I": [".#.", ".#.", ".#.", ".#.", ".#.", ".#."],
    ]

    var body: some View {
        Canvas { context, size in
            let color = themeManager.titleColor
            let highlight = themeManager.titleHighlight
            let shadow = themeManager.titleShadow

            let text: [Character] = Array("CLAUMAGOTCHI")

            var totalW: CGFloat = 0
            for ch in text {
                if let g = Self.font[ch] {
                    totalW += CGFloat(g[0].count) * px + gap
                }
            }
            totalW -= gap

            var x = (size.width - totalW) / 2
            let y = (size.height - 6 * px) / 2

            // Shadow pass (down-right)
            for ch in text {
                guard let glyph = Self.font[ch] else { continue }
                let w = CGFloat(glyph[0].count)
                for (row, line) in glyph.enumerated() {
                    for (col, p) in line.enumerated() where p == "#" {
                        let rect = CGRect(
                            x: x + CGFloat(col) * px + 1,
                            y: y + CGFloat(row) * px + 1,
                            width: px, height: px
                        )
                        context.fill(Path(rect), with: .color(shadow))
                    }
                }
                x += w * px + gap
            }

            // Highlight pass (up-left)
            x = (size.width - totalW) / 2
            for ch in text {
                guard let glyph = Self.font[ch] else { continue }
                let w = CGFloat(glyph[0].count)
                for (row, line) in glyph.enumerated() {
                    for (col, p) in line.enumerated() where p == "#" {
                        let rect = CGRect(
                            x: x + CGFloat(col) * px - 0.4,
                            y: y + CGFloat(row) * px - 0.4,
                            width: px, height: px
                        )
                        context.fill(Path(rect), with: .color(highlight.opacity(0.4)))
                    }
                }
                x += w * px + gap
            }

            // Main pass
            x = (size.width - totalW) / 2
            for ch in text {
                guard let glyph = Self.font[ch] else { continue }
                let w = CGFloat(glyph[0].count)
                for (row, line) in glyph.enumerated() {
                    for (col, p) in line.enumerated() where p == "#" {
                        let rect = CGRect(
                            x: x + CGFloat(col) * px,
                            y: y + CGFloat(row) * px,
                            width: px, height: px
                        )
                        context.fill(Path(rect), with: .color(color))
                    }
                }
                x += w * px + gap
            }
        }
    }
}

// MARK: - Color Hex

extension Color {
    /// Parse a hex string into (r, g, b) components in 0...1 range.
    static func hexComponents(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        switch cleaned.count {
        case 6:
            return (
                r: Double(int >> 16) / 255,
                g: Double(int >> 8 & 0xFF) / 255,
                b: Double(int & 0xFF) / 255
            )
        default:
            return (r: 0, g: 0, b: 0)
        }
    }

    init(hex: String) {
        let c = Self.hexComponents(hex)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b)
    }
}
