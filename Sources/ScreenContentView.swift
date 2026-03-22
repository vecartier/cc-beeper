import SwiftUI

struct ScreenContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animFrame = 0
    @State private var tick = 0
    @State private var isWindowVisible = true

    private let animTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isYoloActive: Bool { monitor.autoAccept }

    var body: some View {
        ZStack {
            Rectangle().fill(themeManager.lcdBg)

            VStack(spacing: 0) {
                // Character animation — fixed size, centered
                PixelCharacterView(state: monitor.state, frame: animFrame,
                                   onColor: themeManager.lcdOn,
                                   isYolo: isYoloActive)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)

                // Status text — 1-2 lines, fixed height, centered
                Text(statusText)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(themeManager.lcdOn)
                    .opacity(monitor.state.needsAttention
                             ? (animFrame % 2 == 0 ? 1 : 0.15) : 1)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 24, maxHeight: 24, alignment: .center)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 3)
            }
            .padding(.horizontal, 4)

            // Pixel grid overlay — retro LCD effect
            Canvas { context, size in
                let lineColor = themeManager.darkMode
                    ? Color.white.opacity(0.04)
                    : themeManager.lcdOn.opacity(0.08)
                let spacing: CGFloat = 3.0
                let lineW: CGFloat = 0.35

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
        }
        .onReceive(animTimer) { _ in
            if isWindowVisible { animFrame += 1 }
        }
        .onReceive(ticker) { _ in
            // Force re-render so elapsedSeconds updates
            tick += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didChangeOcclusionStateNotification)) { notification in
            if let window = notification.object as? NSWindow {
                isWindowVisible = window.occlusionState.contains(.visible)
            }
        }
    }

    private var statusText: String {
        if isYoloActive && monitor.state != .needsYou {
            return "YOLO MODE"
        }
        switch monitor.state {
        case .thinking:
            let tool = truncate(monitor.currentTool ?? "Working", to: 12)
            let elapsed = monitor.elapsedSeconds
            return "\(tool) \u{00B7} \(elapsed)s"
        case .finished:
            return monitor.lastSummary ?? "Done"
        case .needsYou:
            if let p = monitor.pendingPermission {
                let toolName = p.tool
                let fileName = truncateFilename(p.summary)
                return "\(toolName) \u{00B7} \(fileName)"
            }
            return "NEEDS YOU!"
        case .idle:
            return "ZZZ..."
        }
    }

    private func truncate(_ s: String, to n: Int) -> String {
        s.count <= n ? s : String(s.prefix(n - 1)) + "\u{2026}"
    }

    private func truncateFilename(_ s: String) -> String {
        let last = s.split(separator: "/").last.map(String.init) ?? s
        return truncate(last, to: 14)
    }
}
