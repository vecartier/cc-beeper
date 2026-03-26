import Foundation
import AVFoundation
import FoundationModels

final class TTSService: ObservableObject, @unchecked Sendable {

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: TTSSpeechDelegate?

    // OpenAI TTS playback (must be instance property — prevents ARC deallocation during playback)
    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: OpenAITTSDelegate?

    // MARK: - Logging

    private static let logPath = NSHomeDirectory() + "/.claude/cc-beeper/tts.log"

    private func log(_ msg: String) {
        let line = "[\(Date())] \(msg)\n"
        if let fh = FileHandle(forWritingAtPath: Self.logPath) {
            fh.seekToEndOfFile()
            fh.write(line.data(using: .utf8)!)
            fh.closeFile()
        } else {
            FileManager.default.createFile(
                atPath: Self.logPath, contents: line.data(using: .utf8),
                attributes: [.posixPermissions: 0o600]
            )
        }
    }

    // MARK: - Public API

    /// Speak the given text directly. For long text, uses last paragraph. Returns what was spoken.
    func speakSummary(_ text: String, provider: String = "apple") async -> String {
        let toSpeak = text
        await MainActor.run { speak(toSpeak, provider: provider) }
        return toSpeak
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
        // Give audio session time to fully release
        usleep(100_000)
    }

    // MARK: - Summarization

    private func summarize(_ text: String) async -> String {
        if text.count < 200 { return text }

        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            log("Apple Intelligence unavailable — using lastParagraph fallback")
            return lastParagraph(of: text)
        }

        let session = LanguageModelSession {
            """
            You are reading an AI coding assistant's response. \
            Extract ONLY the final conclusion — what was done and what the user should do next. \
            Say it in first person as the assistant. Keep it to 1-3 short sentences. \
            Skip all code, file paths, commands, and technical details.
            """
        }
        do {
            let response = try await session.respond(to: String(text.suffix(2000)))
            let summary = response.content
            log("AI summary: \(summary)")
            return summary.isEmpty ? lastParagraph(of: text) : summary
        } catch {
            log("AI summarization error: \(error)")
            return lastParagraph(of: text)
        }
    }

    private func lastParagraph(of text: String) -> String {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
            .last ?? text
    }

    // MARK: - TTS Dispatcher

    private func speak(_ text: String, provider: String = "apple") {
        guard !text.isEmpty else { return }
        switch provider {
        case "groq":
            if let key = KeychainService.load(account: KeychainService.groqAccount) {
                speakWithGroq(text, apiKey: key)
            } else {
                log("Groq TTS: no API key — falling back to Apple voice")
                speakWithAva(text)
            }
        case "openai":
            if let key = KeychainService.load(account: KeychainService.openAIAccount) {
                speakWithOpenAI(text, apiKey: key)
            } else {
                log("OpenAI TTS: no API key — falling back to Apple voice")
                speakWithAva(text)
            }
        default: // "apple" or any unknown value
            speakWithAva(text)
        }
    }

    // MARK: - OpenAI TTS Path

    private func speakWithOpenAI(_ text: String, apiKey: String) {
        log("OpenAI TTS: speaking: \(text.prefix(200))")
        isSpeaking = true

        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
                request.httpMethod = "POST"
                // Both OpenAI and Groq use standard "Bearer" authorization
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "model": "tts-1",
                    "input": text,
                    "voice": "nova",
                    "response_format": "mp3",
                    "speed": 0.95
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let bodyStr = String(data: data, encoding: .utf8) ?? "(no body)"
                    log("OpenAI TTS error \(httpResponse.statusCode): \(bodyStr)")
                    await MainActor.run { self.speakWithAva(text) }
                    return
                }

                await MainActor.run {
                    do {
                        let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
                        self.playerDelegate = OpenAITTSDelegate { [weak self] in
                            Task { @MainActor in
                                self?.isSpeaking = false
                                self?.audioPlayer = nil
                            }
                        }
                        player.delegate = self.playerDelegate
                        self.audioPlayer = player
                        player.play()
                        self.log("OpenAI TTS: playback started")
                    } catch {
                        self.log("OpenAI TTS: AVAudioPlayer failed: \(error)")
                        self.speakWithAva(text)
                    }
                }
            } catch {
                log("OpenAI TTS: network error: \(error)")
                await MainActor.run { self.speakWithAva(text) }
            }
        }
    }

    // MARK: - Groq TTS Path

    private func speakWithGroq(_ text: String, apiKey: String) {
        log("Groq TTS: speaking: \(text.prefix(200))")
        isSpeaking = true

        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/audio/speech")!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "model": "playai-tts",
                    "input": text,
                    "voice": "Arista-PlayAI",
                    "response_format": "mp3"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let bodyStr = String(data: data, encoding: .utf8) ?? "(no body)"
                    log("Groq TTS error \(httpResponse.statusCode): \(bodyStr)")
                    await MainActor.run { self.speakWithAva(text) }
                    return
                }

                await MainActor.run {
                    do {
                        let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
                        self.playerDelegate = OpenAITTSDelegate { [weak self] in
                            Task { @MainActor in
                                self?.isSpeaking = false
                                self?.audioPlayer = nil
                            }
                        }
                        player.delegate = self.playerDelegate
                        self.audioPlayer = player
                        player.play()
                        self.log("Groq TTS: playback started")
                    } catch {
                        self.log("Groq TTS: AVAudioPlayer failed: \(error)")
                        self.speakWithAva(text)
                    }
                }
            } catch {
                log("Groq TTS: network error: \(error)")
                await MainActor.run { self.speakWithAva(text) }
            }
        }
    }

    // MARK: - Ava TTS Path

    private func speakWithAva(_ text: String) {
        guard !text.isEmpty else { return }
        log("speaking: \(text.prefix(200))")
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

final class OpenAITTSDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { onFinish() }
}
