import SwiftUI

struct SettingsVoiceSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    private let kokoroVoices: [(id: String, label: String, group: String)] = [
        ("bm_daniel", "Daniel", "🇬🇧 British Male"),
        ("bm_george", "George", "🇬🇧 British Male"),
        ("bm_lewis", "Lewis", "🇬🇧 British Male"),
        ("bm_fable", "Fable", "🇬🇧 British Male"),
        ("bf_alice", "Alice", "🇬🇧 British Female"),
        ("bf_emma", "Emma", "🇬🇧 British Female"),
        ("bf_isabella", "Isabella", "🇬🇧 British Female"),
        ("bf_lily", "Lily", "🇬🇧 British Female"),
        ("am_adam", "Adam", "🇺🇸 American Male"),
        ("am_echo", "Echo", "🇺🇸 American Male"),
        ("am_eric", "Eric", "🇺🇸 American Male"),
        ("am_michael", "Michael", "🇺🇸 American Male"),
        ("am_liam", "Liam", "🇺🇸 American Male"),
        ("af_heart", "Heart", "🇺🇸 American Female"),
        ("af_bella", "Bella", "🇺🇸 American Female"),
        ("af_nicole", "Nicole", "🇺🇸 American Female"),
        ("af_nova", "Nova", "🇺🇸 American Female"),
        ("af_sarah", "Sarah", "🇺🇸 American Female"),
        ("af_sky", "Sky", "🇺🇸 American Female"),
    ]

    var body: some View {
        Section("TTS Provider") {
            Picker("Provider", selection: $monitor.ttsProvider) {
                Text("Kokoro (local)").tag("kokoro")
                Text("Apple").tag("apple")
            }
            .pickerStyle(.menu)
        }

        if monitor.ttsProvider == "kokoro" {
            Section("Kokoro Voice") {
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
        }

    }
}
