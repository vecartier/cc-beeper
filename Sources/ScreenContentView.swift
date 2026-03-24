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
            Rectangle().fill(themeManager.darkMode ? themeManager.lcdBg : Color.clear)

            HStack(spacing: 8) {
                // Character — smaller
                PixelCharacterView(
                    state: monitor.state,
                    frame: animFrame,
                    onColor: themeManager.lcdOn,
                    isYolo: isYoloActive
                )
                .frame(width: 34, height: 26)

                // Status: big title + small detail
                VStack(alignment: .leading, spacing: 1) {
                    Text(titleText)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(themeManager.lcdOn)
                        .opacity(monitor.state.needsAttention
                                 ? (animFrame % 2 == 0 ? 1 : 0.15) : 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let detail = detailText {
                        Text(detail)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(themeManager.lcdOn.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // YOLO badge
                if isYoloActive {
                    Text("YOLO")
                        .font(.system(size: 6, weight: .black, design: .monospaced))
                        .foregroundColor(themeManager.lcdOn.opacity(0.6))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(themeManager.lcdOn.opacity(0.3), lineWidth: 0.5)
                        )
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
    }

    // MARK: - Text

    private var titleText: String {
        switch monitor.state {
        case .thinking:
            return "Working..."
        case .finished:
            return "Done!"
        case .needsYou:
            return "Needs you!"
        case .idle:
            return "ZZZ..."
        }
    }

    private var detailText: String? {
        switch monitor.state {
        case .thinking:
            let tool = humanToolName(monitor.currentTool ?? "")
            let elapsed = monitor.elapsedSeconds
            return "\(tool) · \(elapsed)s"
        case .needsYou:
            if let p = monitor.pendingPermission {
                let tool = humanToolName(p.tool)
                let file = truncateFilename(p.summary)
                return "\(tool) · \(file)"
            }
            return nil
        case .finished:
            if let summary = monitor.lastSummary, summary != "Done!" {
                return truncate(summary, to: 36)
            }
            return nil
        case .idle:
            return nil
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
        default: return truncate(tool, to: 12)
        }
    }

    private func truncate(_ s: String, to n: Int) -> String {
        s.count <= n ? s : String(s.prefix(n - 1)) + "\u{2026}"
    }

    private func truncateFilename(_ s: String) -> String {
        let last = s.split(separator: "/").last.map(String.init) ?? s
        return truncate(last, to: 22)
    }
}
