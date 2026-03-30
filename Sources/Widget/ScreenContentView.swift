import SwiftUI

struct ScreenContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animFrame = 0
    @State private var tick = 0
    @State private var isWindowVisible = true
    @State private var bounceOffset: CGFloat = 0

    private let animTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isYoloActive: Bool { monitor.autoAccept }

    var body: some View {
        ZStack {
            Rectangle().fill(themeManager.darkMode ? themeManager.lcdBg : Color.clear)

            HStack(spacing: 8) {
                // Character
                PixelCharacterView(
                    state: monitor.state,
                    frame: animFrame,
                    onColor: themeManager.lcdOn,
                    isYolo: isYoloActive
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
        case .working: return monitor.state.label
        case .done: return monitor.state.label
        case .approveQuestion: return monitor.state.label
        case .needsInput: return monitor.state.label
        case .error: return monitor.state.label
        case .idle: return monitor.state.label
        // TODO: Phase 36 Plan 02 — full text wiring pending
        }
    }

    private var detailText: String? {
        switch monitor.state {
        case .working:
            let tool = humanToolName(monitor.currentTool ?? "")
            let elapsed = monitor.elapsedSeconds
            return "\(tool) · \(elapsed)s"
        case .approveQuestion:
            if let p = monitor.pendingPermission {
                let tool = humanToolName(p.tool)
                return "\(tool) · \(p.summary)"
            }
            return nil
        case .done:
            if let summary = monitor.lastSummary, summary != "Done!" {
                return summary
            }
            return nil
        case .needsInput:
            return monitor.inputMessage
        case .error:
            return monitor.errorDetail
        case .idle:
            return nil
        // TODO: Phase 36 Plan 02 — full animation wiring pending
        }
    }

    private func humanToolName(_ tool: String) -> String {
        switch tool.lowercased() {
        case "bash": return "Running"
        case "read": return "Reading"
        case "write": return "Writing"
        case "edit": return "Editing"
        case "grep": return "Searching"
        case "glob": return "Finding"
        case "agent": return "Thinking"
        case "webfetch": return "Fetching"
        case "websearch": return "Searching"
        default: return tool
        }
    }
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
