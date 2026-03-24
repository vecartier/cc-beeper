import SwiftUI
import AVFoundation
import AppKit

struct ContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    private let shellW: CGFloat = 360
    private let shellH: CGFloat = 160

    // LCD screen
    private let lcdW: CGFloat = 286
    private let lcdH: CGFloat = 45

    // Vibration
    @State private var lastVibrateState: ClaudeState?
    @State private var reminderTimer: Timer?

    // LED pulse
    @State private var ledPulse = false
    private let ledTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Shell background
            Image(nsImage: loadShellImage(themeManager.shellImageName))
                .resizable()
                .interpolation(.high)
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
                .clipped()
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
                        autoSpeak: monitor.ttsService.isSpeaking,
                        action: { monitor.ttsService.stopSpeaking() }
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
        .padding(40)
        .background(Color.clear)
        .contextMenu {
            Button("Quit Claumagotchi") { NSApplication.shared.terminate(nil) }
        }
        .onReceive(monitor.$state) { newState in
            handleStateChange(newState)
        }
        .onReceive(ledTimer) { _ in
            if monitor.state == .thinking || monitor.state == .needsYou {
                ledPulse.toggle()
            }
        }
    }

    // MARK: - State handling

    private func handleStateChange(_ newState: ClaudeState) {
        // LED pulse
        if !(newState == .thinking || newState == .needsYou) {
            ledPulse = false
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
                if monitor.vibrationEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        vibrate()
                    }
                }
                reminderTimer?.invalidate()
                reminderTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak monitor] _ in
                    Task { @MainActor in
                        guard let monitor else { return }
                        if monitor.state == .needsYou && monitor.vibrationEnabled {
                            vibrate()
                        }
                    }
                }
            }
        } else {
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

    // MARK: - Vibration (window-based, no view offset)

    private func vibrate() {
        // 3 short beeps
        playBeeps()

        // Shake the window
        guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) else { return }
        let origin = window.frame.origin
        let shakes = 60
        let distance: CGFloat = 3
        let total = 3.0
        let interval = total / Double(shakes)

        for i in 0..<shakes {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                let dx: CGFloat = (i % 2 == 0) ? distance : -distance
                window.setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            window.setFrameOrigin(origin)
        }
    }

    private func playBeeps() {
        guard monitor.soundEnabled else { return }
        // 3 short beeps with pauses
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                NSSound(named: "Tink")?.play()
            }
        }
    }

    private func loadShellImage(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/" + name) { return img }
        return NSImage()
    }
}

#Preview {
    ContentView()
        .environmentObject(ClaudeMonitor())
        .environmentObject(ThemeManager())
}
