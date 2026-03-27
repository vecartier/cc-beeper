import SwiftUI

struct SettingsAudioSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    private let kokoroVoices: [(id: String, label: String, group: String)] = [
        // British Male
        ("bm_daniel", "Daniel", "🇬🇧 British Male"),
        ("bm_george", "George", "🇬🇧 British Male"),
        ("bm_lewis", "Lewis", "🇬🇧 British Male"),
        ("bm_fable", "Fable", "🇬🇧 British Male"),
        // British Female
        ("bf_alice", "Alice", "🇬🇧 British Female"),
        ("bf_emma", "Emma", "🇬🇧 British Female"),
        ("bf_isabella", "Isabella", "🇬🇧 British Female"),
        ("bf_lily", "Lily", "🇬🇧 British Female"),
        // American Male
        ("am_adam", "Adam", "🇺🇸 American Male"),
        ("am_echo", "Echo", "🇺🇸 American Male"),
        ("am_eric", "Eric", "🇺🇸 American Male"),
        ("am_michael", "Michael", "🇺🇸 American Male"),
        ("am_liam", "Liam", "🇺🇸 American Male"),
        // American Female
        ("af_heart", "Heart", "🇺🇸 American Female"),
        ("af_bella", "Bella", "🇺🇸 American Female"),
        ("af_nicole", "Nicole", "🇺🇸 American Female"),
        ("af_nova", "Nova", "🇺🇸 American Female"),
        ("af_sarah", "Sarah", "🇺🇸 American Female"),
        ("af_sky", "Sky", "🇺🇸 American Female"),
    ]

    var body: some View {
        Toggle(isOn: $monitor.voiceOver) {
            Label("VoiceOver", systemImage: "speaker.wave.2.fill")
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
            Text("Kokoro (local)").tag("kokoro")
            Text("Apple").tag("apple")
        }
        .pickerStyle(.menu)

        if monitor.ttsProvider == "kokoro" {
            HStack {
                Picker("Voice", selection: $monitor.kokoroVoice) {
                    ForEach(kokoroVoices, id: \.id) { voice in
                        Text("\(voice.group) — \(voice.label)").tag(voice.id)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    monitor.ttsService.stopSpeaking()
                    Task {
                        await monitor.ttsService.speakSummary(
                            "Hello, I'm \(monitor.kokoroVoice). This is how I sound.",
                            provider: "kokoro"
                        )
                    }
                } label: {
                    Image(systemName: "play.circle")
                }
                .buttonStyle(.plain)
                .help("Preview voice")
            }
        }

        Toggle(isOn: $monitor.vibrationEnabled) {
            Label("Vibration", systemImage: "waveform")
        }
        .toggleStyle(.switch)
    }
}
