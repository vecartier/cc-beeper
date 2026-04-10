import Foundation
@preconcurrency import FluidAudio

/// Actor wrapping FluidAudio's KokoroTtsManager lifecycle for on-device Kokoro TTS synthesis.
///
/// Usage:
///   - Check `KokoroService.modelsDownloaded` before routing to Kokoro path (cheap disk stat, no load).
///   - Use `KokoroService.shared` singleton — initialize once, then call `synthesize()` repeatedly.
actor KokoroService {

    // MARK: - Singleton

    static let shared = KokoroService()

    // MARK: - Internal State

    private var manager: KokoroTtsManager?

    private init() {}

    // MARK: - Model Presence Check (cheap disk stat, no load)

    /// Returns true if Kokoro CoreML models are present on disk.
    /// Cheap directory-existence check — does NOT load the model.
    static var modelsDownloaded: Bool {
        guard let cacheDir = try? TtsModels.cacheDirectoryURL() else { return false }
        let modelsDir = cacheDir.appendingPathComponent("Models/kokoro")
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: modelsDir.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: modelsDir.path)) ?? []
        return !contents.isEmpty
    }

    // MARK: - Model Download with Progress (called from onboarding)

    /// Download Kokoro models from HuggingFace with progress reporting.
    /// After completion, the manager is ready for use — no separate `initialize()` call needed.
    ///
    /// - Parameter onProgress: Called on arbitrary thread with (fraction 0..1, label string).
    func downloadModels(onProgress: @escaping @Sendable (Double, String) -> Void) async throws {
        let models = try await TtsModels.download { progress in
            onProgress(progress.fractionCompleted, "\(progress.phase)")
        }
        let m = KokoroTtsManager(defaultVoice: "bm_daniel")
        try await m.initialize(models: models, preloadVoices: nil)
        self.manager = m
    }

    // MARK: - Initialize from Disk (load already-downloaded models, no network)

    /// Load the Kokoro model from disk into memory.
    /// Call once before first synthesis (or lazily on first use from TTSService).
    func initialize(defaultVoice: String = "bm_daniel") async throws {
        let m = KokoroTtsManager(defaultVoice: defaultVoice)
        try await m.initialize(preloadVoices: nil)
        self.manager = m
    }

    // MARK: - Synthesize

    /// Synthesize text to WAV audio data using the Kokoro model.
    /// Returns 16-bit PCM WAV at 24 000 Hz — playable with AVAudioPlayer(data:fileTypeHint:"wav").
    func synthesize(text: String, voice: String? = nil) async throws -> Data {
        if manager == nil {
            try await initialize(defaultVoice: voice ?? "bm_daniel")
        }
        guard let manager else {
            throw KokoroServiceError.notInitialized
        }
        return try await manager.synthesize(text: text, voice: voice)
    }

    // MARK: - Voice Selection

    /// Update the default voice used for synthesis.
    func setDefaultVoice(_ voice: String) async {
        try? await manager?.setDefaultVoice(voice)
    }

    // MARK: - Readiness Check

    var isReady: Bool {
        manager != nil
    }
}

// MARK: - Errors

enum KokoroServiceError: Error, LocalizedError {
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "KokoroService: model not initialized — call initialize() before synthesizing"
        }
    }
}
