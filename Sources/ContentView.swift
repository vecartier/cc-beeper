import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    private let shellW: CGFloat = 360
    private let shellH: CGFloat = 160

    // LCD screen
    private let lcdW: CGFloat = 286
    private let lcdH: CGFloat = 45

    // Vibration
    @State private var shakeOffset: CGFloat = 0
    @State private var lastVibrateState: ClaudeState?
    @State private var reminderTimer: Timer?

    // LED pulse
    @State private var ledPulse = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Shell background
            Image(nsImage: loadShellImage(themeManager.shellImageName))
                .resizable()
                .frame(width: shellW, height: shellH)

            // LED indicators — top right of bezel
            HStack(spacing: 4) {
                Circle()
                    .fill(ledGreenColor)
                    .frame(width: 5, height: 5)
                    .shadow(color: ledGreenColor.opacity(0.6), radius: ledGreenGlow ? 3 : 0)
                Circle()
                    .fill(ledAlertColor)
                    .frame(width: 5, height: 5)
                    .opacity(ledAlertActive ? (ledPulse ? 1.0 : 0.3) : 1.0)
                    .shadow(color: ledAlertColor.opacity(0.6), radius: ledAlertActive && ledPulse ? 4 : 0)
            }
            .offset(x: 302, y: 20)

            // LCD screen
            ScreenView()
                .frame(width: lcdW, height: lcdH)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .offset(x: 40, y: 33)
                .allowsHitTesting(false)

            // Buttons — compact group
            HStack(alignment: .center, spacing: -16) {
                AcceptDenyPill(
                    active: monitor.state.needsAttention,
                    onAccept: { monitor.respondToPermission(allow: true) },
                    onDeny: { monitor.respondToPermission(allow: false) }
                )

                HStack(spacing: -24) {
                    RecordButton(
                        isRecording: monitor.isRecording,
                        action: { monitor.voiceService.toggle() }
                    )
                    SoundMuteButton(
                        autoSpeak: monitor.autoSpeak,
                        action: { monitor.autoSpeak.toggle() }
                    )
                }

                TerminalButton(
                    enabled: true,
                    action: { monitor.goToConversation() }
                )
            }
            .offset(x: 16, y: shellH - 72)
        }
        .frame(width: shellW, height: shellH)
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 6)
        .padding(40)
        .offset(x: shakeOffset)
        .background(Color.clear)
        .contextMenu {
            Button("Quit Claumagotchi") { NSApplication.shared.terminate(nil) }
        }
        .onReceive(monitor.$state) { newState in
            handleStateChange(newState)
        }
    }

    // MARK: - State handling

    private func handleStateChange(_ newState: ClaudeState) {
        // LED pulse animation
        if newState == .thinking || newState == .needsYou {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                ledPulse = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                ledPulse = false
            }
        }

        // Vibration on done
        if monitor.vibrationEnabled && newState == .finished && lastVibrateState != newState {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                vibrate()
            }
        }

        // Needs permission: vibrate now + repeat every 15s
        if newState == .needsYou {
            if lastVibrateState != newState {
                // First vibration
                if monitor.vibrationEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        vibrate()
                    }
                }
                // Start reminder timer
                reminderTimer?.invalidate()
                reminderTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                    if monitor.state == .needsYou && monitor.vibrationEnabled {
                        vibrate()
                    }
                }
            }
        } else {
            // Stop reminder timer when no longer needs attention
            reminderTimer?.invalidate()
            reminderTimer = nil
        }

        lastVibrateState = newState
    }

    // MARK: - LEDs

    private var ledGreenColor: Color {
        switch monitor.state {
        case .thinking, .needsYou: return Color(white: 0.35)
        default: return Color(hex: "4ADE80")
        }
    }

    private var ledGreenGlow: Bool {
        monitor.state == .finished || monitor.state == .idle
    }

    private var ledAlertColor: Color {
        switch monitor.state {
        case .thinking, .needsYou: return Color(hex: "FACC15")
        default: return Color(white: 0.35)
        }
    }

    private var ledAlertActive: Bool {
        monitor.state == .thinking || monitor.state == .needsYou
    }

    // MARK: - Vibration

    private func vibrate() {
        let shakes = 12
        let distance: CGFloat = 4
        let total = 0.42  // total duration
        let interval = total / Double(shakes)

        for i in 0..<shakes {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.linear(duration: interval * 0.5)) {
                    shakeOffset = (i % 2 == 0) ? distance : -distance
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 0
            }
        }
    }

    private func loadShellImage(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/" + name) { return img }
        if let img = NSImage(contentsOfFile: "/Users/vcartier/Desktop/Claumagotchi/Sources/shells/" + name) { return img }
        return NSImage()
    }
}

#Preview {
    ContentView()
        .environmentObject(ClaudeMonitor())
        .environmentObject(ThemeManager())
}
