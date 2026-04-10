import SwiftUI

struct SettingsVoiceOverSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    private var currentVoices: [KokoroVoiceCatalog.Voice] {
        KokoroVoiceCatalog.voicesByLang[monitor.kokoroLangCode] ?? KokoroVoiceCatalog.voicesByLang["a"]!
    }

    private var sortedLangCodes: [(code: String, name: String)] {
        KokoroVoiceCatalog.languageNames
            .map { (code: $0.key, name: $0.value) }
            .sorted { a, b in
                if a.code == "a" { return true }
                if b.code == "a" { return false }
                return a.name < b.name
            }
    }

    var body: some View {
        Section {
            Toggle(isOn: $monitor.voiceOver) {
                Label("Read Over", systemImage: "speaker.wave.2.fill")
            }
            .toggleStyle(.switch)

            Text("When enabled, Claude's responses are read aloud automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Speech Synthesis") {
            Picker("Provider", selection: $monitor.ttsProvider) {
                Text("Kokoro (local)").tag("kokoro")
                Text("Apple").tag("apple")
            }
            .pickerStyle(.menu)

            if monitor.ttsProvider == "kokoro" {
                Picker("Language", selection: $monitor.kokoroLangCode) {
                    ForEach(sortedLangCodes, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Picker("Voice", selection: $monitor.kokoroVoice) {
                        ForEach(currentVoices, id: \.id) { voice in
                            Text("\(voice.gender) — \(voice.label)").tag(voice.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        let label = currentVoices.first(where: { $0.id == monitor.kokoroVoice })?.label ?? "this voice"
                        monitor.ttsService.stopSpeaking()
                        Task {
                            await monitor.ttsService.speakSummary(
                                "Hi, I'm \(label). This is how I sound.",
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
