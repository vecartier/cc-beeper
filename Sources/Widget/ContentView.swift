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

    // Buzz service
    private let buzzService = BuzzService()

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

            // Buttons — hidden in compact mode
            if monitor.widgetSize == .large {
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
                            isSpeaking: monitor.ttsService.isSpeaking,
                            action: {
                                if monitor.ttsService.isSpeaking {
                                    monitor.ttsService.stopSpeaking()
                                }
                            }
                        )
                    }

                    TerminalButton(
                        enabled: true,
                        action: { monitor.goToConversation() }
                    )
                }
                .offset(x: 16, y: shellH - 72)
            }
        }
        .frame(width: shellW, height: shellH)
        .padding(40)
        .background(Color.clear)
        .onTapGesture {
            if buzzService.isVibrating {
                buzzService.cancelVibration()
            }
        }
        .contextMenu {
            Button("Quit CC-Beeper") { NSApplication.shared.terminate(nil) }
        }
        .onReceive(monitor.$state) { newState in
            handleStateChange(newState)
        }
        .onReceive(ledTimer) { _ in
            if monitor.state.needsAttention || monitor.state == .working {
                ledPulse.toggle()
            }
        }
    }

    // MARK: - State handling

    private func handleStateChange(_ newState: ClaudeState) {
        // LED pulse
        if !(newState.needsAttention || newState == .working) {
            ledPulse = false
        }

        // Buzz/vibration
        buzzService.handleStateChange(newState, vibrationEnabled: monitor.vibrationEnabled, soundEnabled: monitor.soundEnabled && !monitor.isMuted)
    }

    // MARK: - LEDs

    private var ledGreenColor: Color {
        if monitor.state == .working || monitor.state.needsAttention {
            return AppConstants.ledOff
        }
        return AppConstants.ledGreen
    }

    private var ledGreenGlow: Bool {
        monitor.state == .done || monitor.state == .idle
    }

    private var ledAlertColor: Color {
        if monitor.state == .working || monitor.state.needsAttention {
            return AppConstants.ledAmber
        }
        return AppConstants.ledOff
    }

    private var ledAlertActive: Bool {
        monitor.state == .working || monitor.state.needsAttention
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
