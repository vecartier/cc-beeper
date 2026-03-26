import Foundation
import AVFoundation
import Speech
import AppKit
import ApplicationServices

final class VoiceService: ObservableObject, @unchecked Sendable {

    @Published var isRecording: Bool = false
    @Published var lastTranscriptPreview: String = ""

    /// Set by ClaudeMonitor after both services are created. Used to cut TTS before recording.
    var ttsService: TTSService?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var lastTranscript: String = ""
    private var recordingStartTime: Date?
    private var previousAppPID: pid_t? = nil

    // Groq WAV recording
    private var wavFileURL: URL?
    private var wavAudioFile: AVAudioFile?

    // MARK: - Groq Mode

    private var useGroq: Bool {
        KeychainService.load(account: KeychainService.groqAccount) != nil
    }

    // MARK: - Logging

    private static let logPath = NSHomeDirectory() + "/.claude/cc-beeper/voice.log"

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

    func toggle() {
        if isRecording {
            stopRecording()
        } else {
            // Cut TTS immediately — recording has absolute priority
            if let tts = ttsService, tts.isSpeaking {
                tts.stopSpeaking()
            }
            startRecording()
        }
    }

    func stopIfRecording() {
        if isRecording { stopRecording() }
    }

    // MARK: - Recording

    private func startRecording() {
        log("=== START ===")

        // Check Accessibility — log but don't prompt every time
        let axTrusted = AXIsProcessTrusted()
        log("AX trusted: \(axTrusted)")

        // Recording has absolute priority — kill TTS first
        if let tts = ttsService, tts.isSpeaking {
            tts.stopSpeaking()
            usleep(200_000) // additional wait for full audio session release (stopSpeaking already has 100ms)
            log("killed TTS before recording")
        }

        if isRecording { stopRecording() }

        // Capture previous app BEFORE focusing terminal
        previousAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier

        // Recreate AVAudioEngine each session — do not reuse (prevents headphone corruption)
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        log("format: \(nativeFormat.sampleRate)Hz, \(nativeFormat.channelCount)ch")

        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0 else {
            log("bad format")
            return
        }

        if useGroq {
            startRecordingGroq(inputNode: inputNode, nativeFormat: nativeFormat)
        } else {
            startRecordingSFSpeech(inputNode: inputNode)
        }
    }

    // MARK: - Groq Recording Path

    private func startRecordingGroq(inputNode: AVAudioInputNode, nativeFormat: AVAudioFormat) {
        log("Groq mode: recording WAV")

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("voice-\(UUID().uuidString).wav")

        do {
            wavAudioFile = try AVAudioFile(forWriting: tempURL, settings: nativeFormat.settings)
        } catch {
            log("Groq mode: failed to create WAV file: \(error)")
            return
        }
        wavFileURL = tempURL

        // Install tap that writes buffers to WAV file
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            try? self?.wavAudioFile?.write(from: buffer)
        }
        log("Groq mode: tap installed")

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            recordingStartTime = Date()
            log("Groq mode: recording...")
        } catch {
            log("Groq mode: engine failed: \(error)")
        }
    }

    // MARK: - SFSpeech Recording Path

    private func startRecordingSFSpeech(inputNode: AVAudioInputNode) {
        guard let recognizer else { log("no recognizer"); return }

        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in if status == .authorized { self?.startRecording() } }
            }
            return
        }
        guard authStatus == .authorized else { log("speech not authorized"); return }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in if granted { self?.startRecording() } }
            }
            return
        }
        guard micStatus == .authorized else { log("mic not authorized"); return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        recognitionRequest = request
        lastTranscript = ""

        // format: nil lets the system pick optimal format (works with headphones)
        let capturedRequest = request
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { buffer, _ in
            capturedRequest.append(buffer)
        }
        log("SFSpeech mode: tap installed")

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                self.lastTranscript = text

                // When we get the final result (after endAudio), inject it
                if result.isFinal {
                    self.recognitionTask = nil
                    self.log("final transcript: '\(text)'")
                    self.lastTranscriptPreview = text
                    if !text.isEmpty {
                        self.injectAndSubmit(text)
                    }
                }
            }
            if let error {
                let code = (error as NSError).code
                if code != 216 { // 216 = cancelled, expected
                    self.log("recognition error: \(code)")
                }
            }
        }
        log("recognition task created")

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            recordingStartTime = Date()
            log("SFSpeech mode: recording...")
        } catch {
            log("engine failed: \(error)")
        }
    }

    private func stopRecording() {
        log("=== STOP ===")
        guard isRecording else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false

        if wavAudioFile != nil {
            // Groq mode — close WAV file and dispatch transcription
            wavAudioFile = nil
            let capturedURL = wavFileURL
            wavFileURL = nil
            // Recreate engine per session — prevents corruption on subsequent recordings
            audioEngine = AVAudioEngine()
            log("Groq mode: stopped — dispatching transcription")

            if let url = capturedURL, let key = KeychainService.load(account: KeychainService.groqAccount) {
                Task {
                    do {
                        let text = try await GroqTranscriptionService.transcribe(wavURL: url, apiKey: key)
                        await MainActor.run {
                            self.lastTranscriptPreview = text
                            if !text.isEmpty { self.injectAndSubmit(text) }
                        }
                    } catch {
                        self.log("Groq transcription failed: \(error)")
                        await MainActor.run { self.lastTranscriptPreview = "Groq error" }
                    }
                }
            }
        } else {
            // SFSpeech mode — endAudio and wait for final result
            recognitionRequest?.endAudio()
            recognitionRequest = nil
            // Don't cancel the recognition task — let it deliver the final result
            // Recreate engine per session — prevents corruption on subsequent recordings
            audioEngine = AVAudioEngine()
            log("SFSpeech mode: stopped — waiting for final result")

            // Wait up to 2 seconds for the final transcript to arrive via the callback
            // The recognition callback will set lastTranscript and call injectAndSubmit
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self else { return }
                // If the callback already handled it, recognitionTask will be nil
                if self.recognitionTask != nil {
                    // Timed out — use whatever partial we have
                    let text = self.lastTranscript
                    self.lastTranscript = ""
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    self.log("timeout, using partial: '\(text)'")
                    if !text.isEmpty {
                        self.lastTranscriptPreview = text
                        self.injectAndSubmit(text)
                    }
                }
            }
        }
    }

    // MARK: - Inject text + Enter

    private func injectAndSubmit(_ text: String) {
        guard !text.isEmpty else { return }

        focusTerminal()
        usleep(500_000) // wait for terminal to come forward

        let utf16 = Array(text.utf16)
        if utf16.count <= 200 {
            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
            keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        } else {
            // Clipboard paste fallback for long text
            let pb = NSPasteboard.general
            let old = pb.string(forType: .string)
            pb.clearContents()
            pb.setString(text, forType: .string)
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else { return }
            down.flags = .maskCommand
            up.flags = .maskCommand
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            usleep(100_000)
            if let old { pb.clearContents(); pb.setString(old, forType: .string) }
        }

        // Press Enter
        usleep(100_000)
        guard let enterDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x24, keyDown: true),
              let enterUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x24, keyDown: false) else { return }
        enterDown.post(tap: .cghidEventTap)
        enterUp.post(tap: .cghidEventTap)

        log("injected + submitted: '\(text)'")

        refocusPreviousApp()
    }

    // MARK: - Terminal Focus

    private func focusTerminal() {
        let terminalApps: [(bundleID: String, name: String)] = [
            ("com.apple.Terminal", "Terminal"),
            ("com.googlecode.iterm2", "iTerm"),
            ("dev.warp.Warp-Stable", "Warp"),
            ("io.alacritty", "Alacritty"),
            ("net.kovidgoyal.kitty", "kitty"),
            ("com.github.wez.wezterm", "WezTerm"),
        ]
        for app in NSWorkspace.shared.runningApplications {
            guard let bid = app.bundleIdentifier else { continue }
            if let match = terminalApps.first(where: { $0.bundleID == bid }) {
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = ["-a", match.name]
                try? task.run()
                log("focused terminal via open -a \(match.name)")
                return
            }
        }
        log("no terminal found to focus")
    }

    // MARK: - Refocus Previous App

    private func refocusPreviousApp() {
        guard let pid = previousAppPID else { return }
        usleep(200_000) // brief pause after Enter
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.activate()
            log("refocused previous app (pid \(pid))")
        }
        previousAppPID = nil
    }
}
