import Foundation
import AVFoundation
@preconcurrency import FluidAudio

/// Actor wrapping FluidAudio's StreamingEouAsrManager lifecycle for on-device Parakeet TDT streaming ASR.
///
/// Usage:
///   - Check `ParakeetService.modelsDownloaded` before routing to Parakeet path (cheap disk stat, no load).
///   - Use `ParakeetService.shared` singleton — load once at app launch, call `reset()` between sessions.
///   - Do NOT call `initialize()` or `downloadModels()` on every recording session.
actor ParakeetService {

    // MARK: - Singleton

    static let shared = ParakeetService()

    // MARK: - Internal State

    private var manager: StreamingEouAsrManager?

    private init() {}

    // MARK: - Model Presence Check (cheap disk stat, no load)

    /// Returns true if the Parakeet EOU streaming model directory exists on disk.
    /// This is a cheap `checkResourceIsReachable()` call — does NOT load the model.
    /// Use this from VoiceService to decide which recording path to take.
    static var modelsDownloaded: Bool {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FluidAudio/Models/parakeet-eou-streaming")
        // Check both possible paths (FluidAudio sometimes double-nests the directory)
        let path1 = base.appendingPathComponent("160ms/streaming_encoder.mlmodelc")
        let path2 = base.appendingPathComponent("parakeet-eou-streaming/160ms/streaming_encoder.mlmodelc")
        return FileManager.default.fileExists(atPath: path1.path)
            || FileManager.default.fileExists(atPath: path2.path)
    }

    // MARK: - Model Download with Progress (called from onboarding or first voice press)

    /// Download Parakeet EOU streaming models from HuggingFace with progress reporting.
    /// After completion, the manager is ready for use — no separate `initialize()` call needed.
    ///
    /// - Parameter onProgress: Called on arbitrary thread with (fraction 0..1, label string).
    func downloadModels(onProgress: @escaping @Sendable (Double, String) -> Void) async throws {
        let m = StreamingEouAsrManager(chunkSize: .ms160, eouDebounceMs: 1280)
        try await m.loadModelsFromHuggingFace(
            to: nil, // uses default: ~/Library/Application Support/FluidAudio/Models/parakeet-eou-streaming/
            configuration: nil,
            progressHandler: { progress in
                let label: String
                switch progress.phase {
                case .listing:
                    label = "Preparing..."
                case .downloading(let done, let total):
                    label = "Downloading \(done)/\(total)..."
                case .compiling(let name):
                    label = "Compiling \(name)..."
                }
                onProgress(progress.fractionCompleted, label)
            }
        )
        self.manager = m
    }

    // MARK: - Initialize (downloads + compiles if needed, loads from cache if available)

    /// Load the Parakeet EOU streaming model. Downloads from HuggingFace and compiles CoreML
    /// models on first run. Subsequent launches load from cache instantly.
    /// Do NOT call on every recording session — keep the manager alive and call `reset()` instead.
    func initialize() async throws {
        let m = StreamingEouAsrManager(chunkSize: .ms160, eouDebounceMs: 1280)
        try await m.loadModelsFromHuggingFace(to: nil, configuration: nil, progressHandler: nil)
        self.manager = m
    }

    // MARK: - Configure Callbacks

    /// Set partial and EOU callbacks. Call before each recording session (after `reset()`).
    ///
    /// - Parameters:
    ///   - onPartial: Fires with the FULL accumulated transcript so far on each decoded chunk.
    ///   - onEou: Fires with the final transcript after sustained silence (eouDebounceMs).
    func configureCallbacks(
        onPartial: @escaping @Sendable (String) -> Void,
        onEou: @escaping @Sendable (String) -> Void
    ) async {
        await manager?.setPartialCallback(onPartial)
        await manager?.setEouCallback(onEou)
    }

    // MARK: - Process Audio Buffer

    /// Feed an audio buffer to the Parakeet model.
    /// FluidAudio resamples to 16kHz mono internally — pass the native AVAudioEngine format directly.
    /// Call from the AVAudioEngine tap callback via `Task { try? await parakeetService.process(buffer) }`.
    func process(_ buffer: AVAudioPCMBuffer) async throws {
        _ = try await manager?.process(audioBuffer: buffer)
    }

    // MARK: - Finish

    /// Flush the final audio chunk and return the complete transcript.
    /// Call when the user stops recording (after removing the AVAudioEngine tap).
    func finish() async throws -> String {
        return try await manager?.finish() ?? ""
    }

    // MARK: - Reset

    /// Clear accumulated token state for the next recording session.
    /// Call before each recording session — do NOT re-initialize the manager.
    func reset() async {
        await manager?.reset()
    }

    // MARK: - Readiness Check

    /// Returns true if the model is loaded and ready to process audio.
    var isReady: Bool {
        manager != nil
    }
}
