import Foundation
import AVFoundation
import os.log

final class TTSService: ObservableObject, @unchecked Sendable {

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: TTSSpeechDelegate?

    // Playback
    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: TTSPlaybackDelegate?

    // Kokoro state
    private var kokoroAvailable: Bool = false
    private var currentVoice: String = "bm_daniel"
    private var currentLangCode: String = "b"
    var onKokoroReady: (() -> Void)?

    // MARK: - Logging

    private static let logger = Logger(subsystem: "com.vecartier.cc-beeper", category: "tts")

    func log(_ msg: String) {
        Self.logger.info("\(msg, privacy: .public)")
        // Also write to file for diagnostics (os.Logger info not persisted)
        let path = NSHomeDirectory() + "/.claude/cc-beeper/tts.log"
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(msg)\n"
        if let d = line.data(using: .utf8) {
            if let fh = FileHandle(forWritingAtPath: path) {
                fh.seekToEndOfFile(); fh.write(d); try? fh.close()
            } else {
                try? d.write(to: URL(fileURLWithPath: path))
            }
        }
    }

    // MARK: - Public API

    /// Speak the given text directly. Returns what was spoken.
    func speakSummary(_ text: String, provider: String = "apple") async -> String {
        await MainActor.run { speak(text, provider: provider) }
        return text
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }

    // MARK: - Kokoro Lifecycle

    func launchKokoro() {
        guard KokoroService.modelsDownloaded else {
            log("Kokoro: models not downloaded — falling back to Apple voice")
            kokoroAvailable = false
            return
        }
        kokoroAvailable = true
        let voice = currentVoice
        // Warm up the model in the background so first speech is fast
        Task { [weak self] in
            do {
                try await KokoroService.shared.initialize(defaultVoice: voice)
                await MainActor.run {
                    self?.log("Kokoro: ready (native Swift)")
                    self?.onKokoroReady?()
                }
            } catch {
                await MainActor.run {
                    self?.log("Kokoro: initialize failed — \(error.localizedDescription)")
                    self?.kokoroAvailable = false
                }
            }
        }
    }

    func setKokoroVoice(_ voice: String) {
        currentVoice = voice
        log("Kokoro: voice set to \(voice)")
        Task { await KokoroService.shared.setDefaultVoice(voice) }
    }

    func setKokoroLangCode(_ code: String) {
        // Kokoro voice IDs encode the language via their first letter (a=US, b=UK, etc.)
        // so no separate language switch is needed — voice change is sufficient.
        currentLangCode = code
        log("Kokoro: lang code set to \(code)")
    }

    func shutdownKokoro() {
        // KokoroService manages its own lifecycle — nothing to tear down here.
    }

    // MARK: - TTS Dispatcher

    private func speak(_ text: String, provider: String = "apple") {
        guard !text.isEmpty else { return }
        switch provider {
        case "kokoro":
            guard kokoroAvailable else {
                log("Kokoro unavailable — using Apple voice")
                speakWithAva(text)
                return
            }
            speakWithKokoro(text)
        default:
            speakWithAva(text)
        }
    }

    // MARK: - Kokoro Path

    private func speakWithKokoro(_ text: String) {
        log("Kokoro: speaking: \(text.prefix(200))")
        isSpeaking = true

        let voice = currentVoice
        Task { [weak self] in
            do {
                let data = try await KokoroService.shared.synthesize(text: text, voice: voice)
                await MainActor.run {
                    self?.playWavData(data)
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.log("Kokoro: synthesis failed — \(error.localizedDescription) — falling back to Apple")
                    self.isSpeaking = false
                    self.speakWithAva(text)
                }
            }
        }
    }

    private func playWavData(_ data: Data) {
        do {
            let player = try AVAudioPlayer(data: data, fileTypeHint: "wav")
            playerDelegate = TTSPlaybackDelegate { [weak self] in
                DispatchQueue.main.async {
                    self?.isSpeaking = false
                    self?.audioPlayer = nil
                    self?.log("Kokoro: playback finished")
                }
            }
            player.delegate = playerDelegate
            audioPlayer = player
            isSpeaking = true
            player.play()
            log("Kokoro: playback started (\(data.count) bytes)")
        } catch {
            log("Kokoro: playback error — \(error.localizedDescription)")
            isSpeaking = false
        }
    }

    // MARK: - Apple TTS Path

    private func speakWithAva(_ text: String) {
        guard !text.isEmpty else { return }
        log("speaking with Apple: \(text.prefix(200))")
        if isSpeaking { synthesizer.stopSpeaking(at: .immediate) }

        let utterance = AVSpeechUtterance(string: text)
        if let premium = AVSpeechSynthesisVoice(identifier: "com.apple.voice.premium.en-US.Ava") {
            utterance.voice = premium
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.05

        speechDelegate = TTSSpeechDelegate { [weak self] in
            guard let self else { return }
            Task { @MainActor in self.isSpeaking = false }
        }
        synthesizer.delegate = speechDelegate
        isSpeaking = true
        synthesizer.speak(utterance)
    }
}

// MARK: - Speech Delegates

final class TTSSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { onFinish() }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { onFinish() }
}

final class TTSPlaybackDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { onFinish() }
}
