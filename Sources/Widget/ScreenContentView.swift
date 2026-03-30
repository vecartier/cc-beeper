import SwiftUI

struct ScreenContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animFrame = 0
    @State private var tick = 0
    @State private var isWindowVisible = true
    @State private var bounceOffset: CGFloat = 0
    @State private var glitchActive: Bool = false
    @State private var flashVisible: Bool = true
    @State private var flashCount: Int = 0

    private let animTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isYoloActive: Bool { monitor.currentPreset == .yolo }

    var body: some View {
        ZStack {
            Rectangle().fill(themeManager.darkMode ? themeManager.lcdBg : Color.clear)

            HStack(spacing: 8) {
                // Character
                PixelCharacterView(
                    state: monitor.state,
                    frame: animFrame,
                    onColor: themeManager.lcdOn,
                    isYolo: isYoloActive,
                    isGlitching: glitchActive
                )
                .frame(width: 35, height: 30)
                .offset(y: bounceOffset)

                // Status: big title + scrolling detail
                VStack(alignment: .leading, spacing: 1) {
                    Text(titleText)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(themeManager.lcdOn)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .opacity(titleOpacity)

                    if let detail = detailText {
                        MarqueeText(text: detail, font: .system(size: 8, weight: .medium, design: .monospaced), color: themeManager.lcdOn.opacity(0.7))
                            .frame(height: 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // YOLO badge
                if isYoloActive {
                    HStack(spacing: 3) {
                        Image(systemName: "hare.fill")
                            .font(.system(size: 9))
                        Text("YOLO")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                    }
                    .foregroundColor(themeManager.lcdOn)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(themeManager.lcdOn.opacity(0.6), lineWidth: 1)
                    )
                    .offset(x: -2, y: -8)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, 3)

            // Auth flash overlay (LCD-07) — shows over current content for 2-3s
            if let flashText = monitor.authFlashMessage {
                Text(flashText)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(themeManager.lcdOn)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(themeManager.darkMode ? themeManager.lcdBg.opacity(0.9) : Color.clear.opacity(0.9))
                    .transition(.opacity)
            }

// Vignette
            RadialGradient(
                colors: [.clear, Color(hex: "1A3008").opacity(0.25)],
                center: .center,
                startRadius: 60,
                endRadius: 160
            )
            .allowsHitTesting(false)

            // Pixel grid
            Canvas { context, size in
                let lineColor = Color(hex: "2A4A10").opacity(themeManager.darkMode ? 0.25 : 0.12)
                let spacing: CGFloat = 2.0
                let lineW: CGFloat = 0.5

                var x: CGFloat = spacing
                while x < size.width {
                    context.fill(
                        Path(CGRect(x: x, y: 0, width: lineW, height: size.height)),
                        with: .color(lineColor)
                    )
                    x += spacing
                }
                var y: CGFloat = spacing
                while y < size.height {
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: lineW)),
                        with: .color(lineColor)
                    )
                    y += spacing
                }
            }
            .allowsHitTesting(false)

            // Inner shadow top
            LinearGradient(
                colors: [Color(hex: "1A3008").opacity(0.15), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
        .onReceive(animTimer) { _ in
            if isWindowVisible { animFrame += 1 }
            // Flash on/off — short blink off, longer on
            if flashCount > 0 {
                if !flashVisible {
                    // Was off — turn back on immediately (short off duration)
                    flashVisible = true
                    flashCount -= 1
                    if flashCount == 0 { flashVisible = true }
                } else {
                    // Was on — blink off briefly
                    flashVisible = false
                }
            }
            // Speaking/listening: continuous flash with short off
            if (monitor.state == .speaking || monitor.state == .listening) && flashCount == 0 {
                if animFrame % 4 == 0 {
                    flashVisible = false
                } else {
                    flashVisible = true
                }
            }
        }
        .onReceive(ticker) { _ in
            tick += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didChangeOcclusionStateNotification)) { notification in
            if let window = notification.object as? NSWindow {
                isWindowVisible = window.occlusionState.contains(.visible)
            }
        }
        .onChange(of: monitor.state) { oldState, newState in
            guard oldState != newState else { return }
            // Pick a new random subtitle variant for the new state
            randomVariantIndex = Int.random(in: 0..<100)
            // Reset animation frame
            animFrame = 0
            flashVisible = true

            // Flash 10 times on entry for input, error, permissions, done
            if [.needsInput, .error, .approveQuestion, .done].contains(newState) {
                flashCount = 20  // 20 toggles = 10 full on/off cycles
            } else {
                flashCount = 0
            }

            // Glitch entrance for ERROR
            if newState == .error {
                glitchActive = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    glitchActive = false
                }
            }

            // Bounce animation
            withAnimation(.easeOut(duration: 0.1)) {
                bounceOffset = -4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 0.15)) {
                    bounceOffset = 0
                }
            }
        }
    }

    // MARK: - Text

    private var titleText: String {
        switch monitor.state {
        case .idle: return "Snoozing"
        case .working: return "Working"
        case .done: return "Done!"
        case .error: return "Error"
        case .approveQuestion: return "Allow?"
        case .needsInput: return "Needs input"
        case .listening: return "Listening"
        case .speaking: return "Reading recap"
        }
    }

    // Random subtitle variants — picked once per state entry, stored in randomVariantIndex
    @State private var randomVariantIndex: Int = 0

    private static let idleVariants = ["Idle", "Out cold", "Lights off", "Gone fishing", "Dreaming"]
    private static let workingVariants = ["Running", "Poking", "Busy with", "Tinkering", "Crunching"]
    private static let doneVariants = ["That's a wrap", "Over to you", "Go check", "Your turn", "Fresh out the oven"]
    private static let errorVariants = ["Oops", "Uh oh", "Broke", "Oof", "Welp"]
    private static let approveVariants = ["Knocking", "Requesting", "Asking for", "Let me use", "Pretty please"]
    private static let inputVariants = ["Asks", "Says", "Psst", "Hey", "Paging you"]
    private static let listeningVariants = ["Mic on", "All ears", "Go ahead", "Tuned in", "Copy that"]
    private static let speakingVariants = ["Catching you up", "Here's what happened", "Quick summary", "While you were away", "Last message"]

    private var detailText: String? {
        switch monitor.state {
        case .idle:
            let variant = Self.idleVariants[randomVariantIndex % Self.idleVariants.count]
            if let start = monitor.idleStartTime {
                let elapsed = Int(Date().timeIntervalSince(start))
                let duration: String
                if elapsed < 60 { duration = "\(elapsed)s" }
                else if elapsed < 3600 { duration = "\(elapsed / 60)m" }
                else { duration = "\(elapsed / 3600)h" }
                return "\(variant) \u{00B7} \(duration)"
            }
            return variant
        case .working:
            let variant = Self.workingVariants[randomVariantIndex % Self.workingVariants.count]
            let tool = monitor.currentTool ?? ""
            return tool.isEmpty ? variant : "\(variant) \u{00B7} \(tool)"
        case .done:
            return Self.doneVariants[randomVariantIndex % Self.doneVariants.count]
        case .error:
            let variant = Self.errorVariants[randomVariantIndex % Self.errorVariants.count]
            if let detail = monitor.errorDetail, !detail.isEmpty {
                return "\(variant) \u{00B7} \(detail)"
            }
            return variant
        case .approveQuestion:
            let variant = Self.approveVariants[randomVariantIndex % Self.approveVariants.count]
            if let p = monitor.pendingPermission, !p.tool.isEmpty {
                return "\(variant) \u{00B7} \(p.tool)"
            }
            return variant
        case .needsInput:
            let variant = Self.inputVariants[randomVariantIndex % Self.inputVariants.count]
            if let msg = monitor.inputMessage, !msg.isEmpty {
                return "\(variant) \u{00B7} \(msg)"
            }
            return variant
        case .listening:
            return Self.listeningVariants[randomVariantIndex % Self.listeningVariants.count]
        case .speaking:
            return Self.speakingVariants[randomVariantIndex % Self.speakingVariants.count]
        }
    }

    // MARK: - Animation

    private var titleOpacity: Double { flashVisible ? 1.0 : 0.0 }

    // MARK: - Tool Name (no longer used for subtitle — tool name shown raw now)
}

// MARK: - Marquee Scrolling Text

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let speed: Double = 30

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var scrollTimer: Timer?

    private var needsScroll: Bool { textWidth > containerWidth }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(x: needsScroll ? offset : 0)
                    .onAppear {
                        containerWidth = geo.size.width
                    }
                    .onChange(of: geo.size.width) {
                        containerWidth = geo.size.width
                    }
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textWidth = textGeo.size.width
                                startScrollIfNeeded()
                            }
                            .onChange(of: text) {
                                textWidth = textGeo.size.width
                                offset = 0
                                startScrollIfNeeded()
                            }
                        }
                    )
            }
            .frame(width: geo.size.width, alignment: .leading)
            .clipped()
            .mask(
                HStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .white], startPoint: .leading, endPoint: .trailing)
                        .frame(width: needsScroll ? 8 : 0)
                    Rectangle().fill(Color.white)
                    LinearGradient(colors: [.white, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: needsScroll ? 8 : 0)
                }
            )
        }
    }

    private func startScrollIfNeeded() {
        scrollTimer?.invalidate()
        guard needsScroll else { return }

        let totalDistance = textWidth - containerWidth + 20

        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if offset > -totalDistance {
                offset -= 0.9
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    offset = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startScrollIfNeeded()
                    }
                }
            }
        }
    }
}
