import Foundation
import AVFoundation

final class TTSService: ObservableObject, @unchecked Sendable {

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speechDelegate: TTSSpeechDelegate?

    // TTS playback
    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: TTSPlaybackDelegate?

    // Kokoro subprocess
    private var kokoroProcess: Process?
    private var kokoroStdin: FileHandle?
    private var kokoroReady: Bool = false
    private var pendingKokoroText: String?

    // File-based IPC
    private static let ipcDir = NSHomeDirectory() + "/.claude/cc-beeper"
    private static let outputFile = ipcDir + "/tts-output.wav"
    private static let readyFile = ipcDir + "/tts-ready"
    private var outputWatcher: DispatchSourceFileSystemObject?

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
        usleep(100_000)
    }

    // MARK: - Kokoro Lifecycle

    func launchKokoro() {
        let venvPython = NSHomeDirectory() + "/.cache/cc-beeper/kokoro-venv/bin/python3"
        guard FileManager.default.fileExists(atPath: venvPython) else {
            log("Kokoro: venv not found — run setup-kokoro.sh first")
            return
        }

        let serverScript: String
        if let bundled = Bundle.main.path(forResource: "kokoro-tts-server", ofType: "py") {
            serverScript = bundled
        } else {
            let candidates = [
                NSHomeDirectory() + "/Desktop/CC-Beeper/Sources/kokoro-tts-server.py",
                NSHomeDirectory() + "/Desktop/cc-beeper/Sources/kokoro-tts-server.py",
            ]
            guard let found = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
                log("Kokoro: server script not found")
                return
            }
            serverScript = found
        }

        // Clean up stale files
        try? FileManager.default.removeItem(atPath: Self.readyFile)
        try? FileManager.default.removeItem(atPath: Self.outputFile)

        log("Kokoro: launching subprocess...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: venvPython)
        process.arguments = ["-u", serverScript]
        process.environment = ProcessInfo.processInfo.environment

        let stdinPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = FileHandle.nullDevice  // not used
        process.standardError = stderrPipe

        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            for line in text.split(separator: "\n") {
                self?.log("Kokoro stderr: \(line)")
            }
        }

        do {
            try process.run()
        } catch {
            log("Kokoro: failed to launch: \(error)")
            return
        }

        kokoroProcess = process
        kokoroStdin = stdinPipe.fileHandleForWriting

        // Set up file watcher for tts-output.wav
        setupOutputWatcher()

        // Poll for ready file (subprocess writes it when model is loaded)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for _ in 0..<60 {  // 30 second timeout
                if FileManager.default.fileExists(atPath: Self.readyFile) {
                    DispatchQueue.main.async {
                        self?.kokoroReady = true
                        self?.log("Kokoro: ready")
                        if let pending = self?.pendingKokoroText {
                            self?.pendingKokoroText = nil
                            self?.speakWithKokoro(pending)
                        }
                    }
                    return
                }
                usleep(500_000)
            }
            DispatchQueue.main.async {
                self?.log("Kokoro: timeout waiting for ready")
            }
        }
    }

    private func setupOutputWatcher() {
        // Watch the IPC directory — os.replace() creates a new inode, so watching
        // the file itself doesn't work. Directory watches catch renames into it.
        let fd = open(Self.ipcDir, O_EVTONLY)
        guard fd >= 0 else {
            log("Kokoro: failed to open IPC dir for watching")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write], queue: .main
        )
        source.setEventHandler { [weak self] in self?.onOutputFileChanged() }
        source.setCancelHandler { close(fd) }
        source.resume()
        outputWatcher = source
    }

    private var lastOutputHash: Int = 0

    private func onOutputFileChanged() {
        guard let data = FileManager.default.contents(atPath: Self.outputFile),
              data.count > 44 else { return } // 44 = WAV header minimum
        let hash = data.hashValue
        guard hash != lastOutputHash else { return }
        lastOutputHash = hash

        log("Kokoro: received \(data.count) bytes WAV from file")

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
            player.play()
            log("Kokoro: playback started")
        } catch {
            log("Kokoro: playback error: \(error)")
            isSpeaking = false
        }
    }

    func setKokoroVoice(_ voice: String) {
        guard let stdin = kokoroStdin else { return }
        let cmd = "VOICE:\(voice)\n"
        if let data = cmd.data(using: .utf8) {
            stdin.write(data)
            log("Kokoro: voice set to \(voice)")
        }
    }

    func shutdownKokoro() {
        outputWatcher?.cancel()
        outputWatcher = nil
        kokoroStdin?.closeFile()
        kokoroProcess?.terminate()
        kokoroProcess = nil
        kokoroStdin = nil
        kokoroReady = false
    }

    // MARK: - TTS Dispatcher

    private func speak(_ text: String, provider: String = "apple") {
        guard !text.isEmpty else { return }
        switch provider {
        case "kokoro":
            if kokoroReady {
                speakWithKokoro(text)
            } else {
                log("Kokoro not ready — queuing speech")
                pendingKokoroText = text
            }
        default:
            speakWithAva(text)
        }
    }

    // MARK: - Kokoro Path

    private func speakWithKokoro(_ text: String) {
        log("Kokoro: speaking: \(text.prefix(200))")
        isSpeaking = true

        guard let stdin = kokoroStdin else {
            log("Kokoro: no stdin pipe — falling back to Apple voice")
            speakWithAva(text)
            return
        }

        // Send text to subprocess — it generates WAV and writes to tts-output.wav
        let line = text.replacingOccurrences(of: "\n", with: " ") + "\n"
        guard let data = line.data(using: .utf8) else { return }
        stdin.write(data)
        // File watcher will pick up the result and play it
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

final class TTSPlaybackDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { onFinish() }
}
