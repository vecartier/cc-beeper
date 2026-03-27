import SwiftUI

struct SettingsVoiceOverSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    var body: some View {
        Section {
            Toggle(isOn: $monitor.voiceOver) {
                Label("Voice Reader", systemImage: "speaker.wave.2.fill")
            }
            .toggleStyle(.switch)

            Text("When enabled, Claude's responses are read aloud automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Speech Recognition") {
            HStack {
                Label("STT Engine", systemImage: "waveform.and.mic")
                Spacer()
                Text(monitor.voiceService.sttEngineLabel)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }

    }
}
