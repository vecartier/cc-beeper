import SwiftUI

struct SettingsAudioSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    var body: some View {
        Toggle(isOn: $monitor.autoSpeak) {
            Label("Auto-Speak Summaries", systemImage: "speaker.wave.2.fill")
        }
        .toggleStyle(.switch)

        Toggle(isOn: $monitor.vibrationEnabled) {
            Label("Vibration", systemImage: "waveform")
        }
        .toggleStyle(.switch)

        Toggle(isOn: $monitor.soundEnabled) {
            Label("Sound Effects", systemImage: "speaker.fill")
        }
        .toggleStyle(.switch)
    }
}
