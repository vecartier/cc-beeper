import SwiftUI

struct SettingsAudioSection: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    private let kokoroVoiceGroups: [(group: String, voices: [(id: String, label: String)])] = [
        ("American English", [
            ("af_alloy", "Alloy (F)"), ("af_aoede", "Aoede (F)"), ("af_bella", "Bella (F)"),
            ("af_heart", "Heart (F)"), ("af_jessica", "Jessica (F)"), ("af_kore", "Kore (F)"),
            ("af_nicole", "Nicole (F)"), ("af_nova", "Nova (F)"), ("af_river", "River (F)"),
            ("af_sarah", "Sarah (F)"), ("af_sky", "Sky (F)"),
            ("am_adam", "Adam (M)"), ("am_echo", "Echo (M)"), ("am_eric", "Eric (M)"),
            ("am_fenrir", "Fenrir (M)"), ("am_liam", "Liam (M)"), ("am_michael", "Michael (M)"),
            ("am_onyx", "Onyx (M)"), ("am_puck", "Puck (M)"), ("am_santa", "Santa (M)")
        ]),
        ("British English", [
            ("bf_alice", "Alice (F)"), ("bf_emma", "Emma (F)"), ("bf_isabella", "Isabella (F)"),
            ("bf_lily", "Lily (F)"),
            ("bm_daniel", "Daniel (M)"), ("bm_fable", "Fable (M)"), ("bm_george", "George (M)"),
            ("bm_lewis", "Lewis (M)")
        ]),
        ("Spanish", [
            ("ef_dora", "Dora (F)"), ("em_alex", "Alex (M)"), ("em_santa", "Santa (M)")
        ]),
        ("French", [
            ("ff_siwis", "Siwis (F)")
        ]),
        ("Hindi", [
            ("hf_alpha", "Alpha (F)"), ("hf_beta", "Beta (F)"),
            ("hm_omega", "Omega (M)"), ("hm_psi", "Psi (M)")
        ]),
        ("Italian", [
            ("if_sara", "Sara (F)"), ("im_nicola", "Nicola (M)")
        ]),
        ("Japanese", [
            ("jf_alpha", "Alpha (F)"), ("jf_gongitsune", "Gongitsune (F)"),
            ("jf_nezumi", "Nezumi (F)"), ("jf_tebukuro", "Tebukuro (F)"), ("jm_kumo", "Kumo (M)")
        ]),
        ("Portuguese", [
            ("pf_dora", "Dora (F)"), ("pm_alex", "Alex (M)"), ("pm_santa", "Santa (M)")
        ]),
        ("Mandarin", [
            ("zf_xiaobei", "Xiaobei (F)"), ("zf_xiaoni", "Xiaoni (F)"),
            ("zf_xiaoxiao", "Xiaoxiao (F)"), ("zf_xiaoyi", "Xiaoyi (F)"),
            ("zm_yunjian", "Yunjian (M)"), ("zm_yunxi", "Yunxi (M)"),
            ("zm_yunxia", "Yunxia (M)"), ("zm_yunyang", "Yunyang (M)")
        ])
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

        HStack {
            Label("TTS Engine", systemImage: "speaker.wave.2")
            Spacer()
            Text(KokoroService.modelsDownloaded ? "Kokoro-82M (local)" : "Apple Ava (fallback)")
                .foregroundStyle(.secondary)
                .font(.caption)
        }

        if monitor.ttsProvider == "kokoro" {
            Picker("Kokoro Voice", selection: $monitor.kokoroVoice) {
                ForEach(kokoroVoiceGroups, id: \.group) { group in
                    Section(group.group) {
                        ForEach(group.voices, id: \.id) { voice in
                            Text(voice.label).tag(voice.id)
                        }
                    }
                }
            }
            .pickerStyle(.menu)
        }

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
