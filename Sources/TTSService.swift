import Foundation
import AVFoundation
import FoundationModels

final class TTSService: ObservableObject, @unchecked Sendable {

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: TTSSpeechDelegate?

    // MARK: - Logging

    private func log(_ msg: String) {
        let line = "[\(Date())] \(msg)\n"
        let path = "/tmp/claumagotchi-tts.log"
        if let fh = FileHandle(forWritingAtPath: path) {
            fh.seekToEndOfFile()
            fh.write(line.data(using: .utf8)!)
            fh.closeFile()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Public API

    /// Summarize (if needed) and speak the given text. Returns the summary spoken.
    func speakSummary(_ text: String) async -> String {
        let summary = await summarize(text)
        await MainActor.run { speak(summary) }
        return summary
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
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

    // MARK: - TTS

    private func speak(_ text: String) {
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

// MARK: - Speech Delegate

final class TTSSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { onFinish() }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { onFinish() }
}
