import Foundation

enum KokoroVoiceCatalog {
    struct Voice {
        let id: String
        let label: String
        let gender: String
    }

    static let voicesByLang: [String: [Voice]] = [
        "a": [
            Voice(id: "af_heart", label: "Heart", gender: "Female"),
            Voice(id: "af_alloy", label: "Alloy", gender: "Female"),
            Voice(id: "af_aoede", label: "Aoede", gender: "Female"),
            Voice(id: "af_bella", label: "Bella", gender: "Female"),
            Voice(id: "af_jessica", label: "Jessica", gender: "Female"),
            Voice(id: "af_kore", label: "Kore", gender: "Female"),
            Voice(id: "af_nicole", label: "Nicole", gender: "Female"),
            Voice(id: "af_nova", label: "Nova", gender: "Female"),
            Voice(id: "af_river", label: "River", gender: "Female"),
            Voice(id: "af_sarah", label: "Sarah", gender: "Female"),
            Voice(id: "af_sky", label: "Sky", gender: "Female"),
            Voice(id: "am_adam", label: "Adam", gender: "Male"),
            Voice(id: "am_echo", label: "Echo", gender: "Male"),
            Voice(id: "am_eric", label: "Eric", gender: "Male"),
            Voice(id: "am_fenrir", label: "Fenrir", gender: "Male"),
            Voice(id: "am_liam", label: "Liam", gender: "Male"),
            Voice(id: "am_michael", label: "Michael", gender: "Male"),
            Voice(id: "am_onyx", label: "Onyx", gender: "Male"),
            Voice(id: "am_puck", label: "Puck", gender: "Male"),
            Voice(id: "am_santa", label: "Santa", gender: "Male"),
        ],
        "b": [
            Voice(id: "bf_alice", label: "Alice", gender: "Female"),
            Voice(id: "bf_emma", label: "Emma", gender: "Female"),
            Voice(id: "bf_isabella", label: "Isabella", gender: "Female"),
            Voice(id: "bf_lily", label: "Lily", gender: "Female"),
            Voice(id: "bm_daniel", label: "Daniel", gender: "Male"),
            Voice(id: "bm_fable", label: "Fable", gender: "Male"),
            Voice(id: "bm_george", label: "George", gender: "Male"),
            Voice(id: "bm_lewis", label: "Lewis", gender: "Male"),
        ],
        "e": [
            Voice(id: "ef_dora", label: "Dora", gender: "Female"),
            Voice(id: "em_alex", label: "Alex", gender: "Male"),
            Voice(id: "em_santa", label: "Santa", gender: "Male"),
        ],
        "f": [
            Voice(id: "ff_siwis", label: "Siwis", gender: "Female"),
        ],
        "h": [
            Voice(id: "hf_alpha", label: "Alpha", gender: "Female"),
            Voice(id: "hf_beta", label: "Beta", gender: "Female"),
            Voice(id: "hm_omega", label: "Omega", gender: "Male"),
            Voice(id: "hm_psi", label: "Psi", gender: "Male"),
        ],
        "i": [
            Voice(id: "if_sara", label: "Sara", gender: "Female"),
            Voice(id: "im_nicola", label: "Nicola", gender: "Male"),
        ],
        "p": [
            Voice(id: "pf_dora", label: "Dora", gender: "Female"),
            Voice(id: "pm_alex", label: "Alex", gender: "Male"),
            Voice(id: "pm_santa", label: "Santa", gender: "Male"),
        ],
        "j": [
            Voice(id: "jf_alpha", label: "Alpha", gender: "Female"),
            Voice(id: "jf_gongitsune", label: "Gongitsune", gender: "Female"),
            Voice(id: "jf_nezumi", label: "Nezumi", gender: "Female"),
            Voice(id: "jf_tebukuro", label: "Tebukuro", gender: "Female"),
            Voice(id: "jm_kumo", label: "Kumo", gender: "Male"),
        ],
        "z": [
            Voice(id: "zf_xiaobei", label: "Xiaobei", gender: "Female"),
            Voice(id: "zf_xiaoni", label: "Xiaoni", gender: "Female"),
            Voice(id: "zf_xiaoxiao", label: "Xiaoxiao", gender: "Female"),
            Voice(id: "zf_xiaoyi", label: "Xiaoyi", gender: "Female"),
            Voice(id: "zm_yunjian", label: "Yunjian", gender: "Male"),
            Voice(id: "zm_yunxi", label: "Yunxi", gender: "Male"),
            Voice(id: "zm_yunxia", label: "Yunxia", gender: "Male"),
            Voice(id: "zm_yunyang", label: "Yunyang", gender: "Male"),
        ],
    ]

    static let languageNames: [String: String] = [
        "a": "English (US)",
        "b": "English (UK)",
        "e": "Spanish",
        "f": "French",
        "h": "Hindi",
        "i": "Italian",
        "j": "Japanese",
        "p": "Portuguese",
        "z": "Chinese",
    ]

    /// Languages that require extra pip install before use.
    static let langCodesRequiringDeps: Set<String> = ["j", "z"]

    /// Returns the first voice ID for a given language code, or "af_heart" as ultimate fallback.
    static func defaultVoice(for langCode: String) -> String {
        voicesByLang[langCode]?.first?.id ?? "af_heart"
    }

    /// Returns true if the given voice ID is valid for the given language code.
    static func isVoiceValid(_ voiceId: String, for langCode: String) -> Bool {
        voicesByLang[langCode]?.contains(where: { $0.id == voiceId }) ?? false
    }
}
