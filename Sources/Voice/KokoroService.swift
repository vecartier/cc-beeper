import Foundation
import AVFoundation
import CoreML
@preconcurrency import FluidAudio

/// Actor wrapping FluidAudio's PocketTtsManager lifecycle for on-device PocketTTS synthesis.
///
/// Usage:
///   - Check `PocketTTSService.modelsDownloaded` before routing to PocketTTS path (cheap disk stat, no load).
///   - Use `PocketTTSService.shared` singleton — initialize once, then call `synthesize()` repeatedly.
///   - Do NOT call `initialize()` or `downloadModels()` on every synthesis request.
actor PocketTTSService {

    // MARK: - Singleton

    static let shared = PocketTTSService()

    // MARK: - Internal State

    private var manager: PocketTtsManager?

    private init() {}

    // MARK: - Model Presence Check (cheap disk stat, no load)

    /// Returns true if the PocketTTS model directory exists on disk.
    /// This is a cheap `fileExists` call — does NOT load the model.
    /// Use this from TTSService to decide which TTS path to take.
    static var modelsDownloaded: Bool {
        let modelPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/fluidaudio/Models/pocket-tts")
            .appendingPathComponent("flowlm_step.mlmodelc")
        return FileManager.default.fileExists(atPath: modelPath.path)
    }

    // MARK: - Model Download with Progress (called from onboarding)

    /// Download PocketTTS models from HuggingFace with progress reporting.
    /// After completion, the manager is ready for use — no separate `initialize()` call needed.
    ///
    /// - Parameter onProgress: Called on arbitrary thread with (fraction 0..1, label string).
    func downloadModels(onProgress: @escaping @Sendable (Double, String) -> Void) async throws {
        let m = PocketTtsManager(defaultVoice: "alba")
        try await m.initialize()
        self.manager = m
    }

    // MARK: - Initialize from Disk (load already-downloaded models, no network)

    /// Load the PocketTTS model from disk into memory.
    /// Call once before first synthesis (or lazily on first use from TTSService).
    /// Do NOT call on every synthesis request — keep the manager alive.
    func initialize(defaultVoice: String = "alba") async throws {
        let m = PocketTtsManager(defaultVoice: defaultVoice)
        try await m.initialize()
        self.manager = m
    }

    // MARK: - Synthesize

    /// Synthesize text to WAV audio data using the PocketTTS model.
    /// Returns 16-bit PCM WAV at 24 000 Hz — playable with AVAudioPlayer(data:fileTypeHint:.wav).
    ///
    /// - Parameters:
    ///   - text: Text to synthesize.
    ///   - voice: Optional voice override. Defaults to the manager's configured default voice.
    /// - Returns: WAV Data ready for AVAudioPlayer playback.
    func synthesize(text: String, voice: String? = nil) async throws -> Data {
        guard let manager else {
            throw PocketTTSServiceError.notInitialized
        }
        return try await manager.synthesize(text: text, voice: voice)
    }

    // MARK: - Streaming Synthesis

    /// Synthesize text as a stream of 80ms audio frames for low-latency playback.
    func synthesizeStreaming(text: String, voice: String? = nil) async throws -> AsyncThrowingStream<PocketTtsSynthesizer.AudioFrame, Error> {
        guard let manager else {
            throw PocketTTSServiceError.notInitialized
        }
        return try await manager.synthesizeStreaming(text: text, voice: voice)
    }

    // MARK: - Voice Selection

    /// Update the default voice used for synthesis.
    func setDefaultVoice(_ voice: String) async {
        await manager?.setDefaultVoice(voice)
    }

    // MARK: - Readiness Check

    /// Returns true if the model is loaded and ready to synthesize.
    var isReady: Bool {
        manager != nil
    }
}

// MARK: - Errors

enum PocketTTSServiceError: Error, LocalizedError {
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "PocketTTSService: model not initialized — call initialize() before synthesizing"
        }
    }
}
