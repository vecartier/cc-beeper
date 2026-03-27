import SwiftUI

struct SettingsAudioSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    var body: some View {
        Toggle(isOn: $monitor.autoSpeak) {
            Label("Auto-Speak Summaries", systemImage: "speaker.wave.2.fill")
        }
        .toggleStyle(.switch)

        HStack {
            Label("STT Engine", systemImage: "waveform.and.mic")
            Spacer()
            Text(monitor.voiceService.sttEngineLabel)
                .foregroundStyle(.secondary)
                .font(.caption)
        }

        Picker("TTS Provider", selection: $monitor.ttsProvider) {
            Text("Apple").tag("apple")
            Text("Groq").tag("groq")
            Text("OpenAI").tag("openai")
        }
        .pickerStyle(.menu)

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
