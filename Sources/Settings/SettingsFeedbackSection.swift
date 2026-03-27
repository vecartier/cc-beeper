import SwiftUI

struct SettingsFeedbackSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    var body: some View {
        Section("Sound Effects") {
            Toggle(isOn: $monitor.soundEnabled) {
                Label("Sound Effects", systemImage: "speaker.fill")
            }
            .toggleStyle(.switch)
        }

        Section("Vibration") {
            Toggle(isOn: $monitor.vibrationEnabled) {
                Label("Vibration", systemImage: "waveform")
            }
            .toggleStyle(.switch)
        }
    }
}
