import Foundation
import AVFoundation
import Speech
import AppKit
import ApplicationServices

final class VoiceService: ObservableObject, @unchecked Sendable {

    /// Shared terminal bundle IDs from AppConstants (FRAG-06).
    private static let terminalBundleIDs = AppConstants.terminalBundleIDs

    @Published var isRecording: Bool = false
    @Published var lastTranscriptPreview: String = ""
    @Published var recordingError: String? = nil

    /// Detected language from last transcription (ISO 639-1 code, e.g. "en", "fr").
    /// Set by Whisper path after each transcription.
    var detectedLanguage: String = "en"

    /// Set by ClaudeMonitor after both services are created. Used to cut TTS before recording.
    var ttsService: TTSService?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var lastTranscript: String = ""
    private var recordingStartTime: Date?
    private var previousAppPID: pid_t? = nil

    // MARK: - Whisper State

    private let whisperService = WhisperService.shared
    private var hasSubmitted: Bool = false        // Guard against double-submit
    private var isWhisperSession: Bool = false    // Which path is currently active
    private var whisperFailed: Bool = false       // True after init failure — skip Whisper until next launch
    private var whisperInitializing: Bool = false // Guard against concurrent init attempts
    private var whisperAudioFrames: [Float] = []  // Accumulates 16kHz mono float32 frames during recording

    // MARK: - STT Engine Label

    /// Exposed to Settings > Voice to show which STT engine is active.
    var sttEngineLabel: String {
        "Whisper (local)"
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

    // MARK: - Recording Router

    private func startRecording() {
        log("=== START ===")

        // Carbon HotKey consumes the event — no modifier cleanup needed

        // Check Accessibility — log but don't prompt every time
        let axTrusted = AXIsProcessTrusted()
        log("AX trusted: \(axTrusted)")

        // Recording has absolute priority — kill TTS first
        if let tts = ttsService, tts.isSpeaking {
            tts.stopSpeaking()
            usleep(200_000) // additional wait for full audio session release
            log("killed TTS before recording")
        }

        if isRecording { stopRecording() }

        // Set recording state SYNCHRONOUSLY before any async work (Bug 1 fix)
        isRecording = true
        hasSubmitted = false
        recordingError = nil

        // Capture previous app BEFORE focusing terminal
        previousAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier

        // Recreate AVAudioEngine each session — do not reuse (prevents headphone corruption)
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        log("format: \(nativeFormat.sampleRate)Hz, \(nativeFormat.channelCount)ch")

        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0 else {
            log("bad format — microphone may be unavailable")
            isRecording = false
            recordingError = "Microphone unavailable"
            return
        }

        log("STT engine: \(sttEngineLabel)")

        // Only use Whisper if it's already initialized (pre-warmed at launch).
        // If not ready yet, use SFSpeech — don't block recording waiting for init.
        Task {
            let ready = await whisperService.isReady
            await MainActor.run {
                if ready && !self.whisperFailed {
                    self.startRecordingWhisper(inputNode: inputNode)
                } else {
                    self.log("Using SFSpeech (whisperReady=\(ready), whisperFailed=\(self.whisperFailed))")
                    self.startRecordingSFSpeech(inputNode: inputNode)
                }
            }
        }
    }

    // MARK: - Whisper Batch Recording Path

    private func startRecordingWhisper(inputNode: AVAudioInputNode) {
        log("Whisper mode: batch recording (no live injection per D-04)")
        isWhisperSession = true

        let nativeFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        )!

        // Build converter from native mic format to 16kHz mono float32 (Pitfall 5 guard)
        guard let converter = AVAudioConverter(from: nativeFormat, to: targetFormat) else {
            log("Whisper mode: AVAudioConverter init failed for format \(nativeFormat) — falling back to SFSpeech")
            isWhisperSession = false
            whisperFailed = true
            startRecordingSFSpeech(inputNode: inputNode)
            return
        }

        // Pre-allocate 60 seconds of 16kHz frames
        whisperAudioFrames = []
        whisperAudioFrames.reserveCapacity(16_000 * 60)

        // Focus terminal ONCE at session start
        focusTerminal()

        // Show LCD feedback during recording
        lastTranscriptPreview = "Recording..."

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            guard let self else { return }

            // Convert to 16kHz mono float32
            let frameCount = AVAudioFrameCount(
                ceil(Double(buffer.frameLength) * 16_000.0 / nativeFormat.sampleRate)
            )
            guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else { return }

            var inputConsumed = false
            converter.convert(to: outBuffer, error: nil) { _, status in
                if inputConsumed {
                    status.pointee = .noDataNow
                    return nil
                }
                inputConsumed = true
                status.pointee = .haveData
                return buffer
            }

            if let data = outBuffer.floatChannelData?[0] {
                let frames = Array(UnsafeBufferPointer(start: data, count: Int(outBuffer.frameLength)))
                // Thread safety: capture local chunk and dispatch to accumulate
                // (Audio tap fires on real-time thread; whisperAudioFrames on main)
                let chunk = frames
                Task { @MainActor [weak self] in
                    self?.whisperAudioFrames.append(contentsOf: chunk)
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            recordingStartTime = Date()
            log("Whisper mode: recording batch frames...")
        } catch {
            log("Whisper mode: engine failed: \(error)")
            inputNode.removeTap(onBus: 0)
            isRecording = false
            recordingError = "Recording failed: \(error)"
        }
    }

    // MARK: - SFSpeech Recording Path

    private func startRecordingSFSpeech(inputNode: AVAudioInputNode) {
        isWhisperSession = false
        guard let recognizer else {
            log("no recognizer")
            isRecording = false
            return
        }

        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus == .notDetermined {
            isRecording = false
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in if status == .authorized { self?.startRecording() } }
            }
            return
        }
        guard authStatus == .authorized else {
            log("speech not authorized")
            isRecording = false
            return
        }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            isRecording = false
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in if granted { self?.startRecording() } }
            }
            return
        }
        guard micStatus == .authorized else {
            log("mic not authorized")
            isRecording = false
            recordingError = "Microphone unavailable"
            return
        }

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
            // isRecording already set true synchronously in startRecording() (Bug 1 fix)
            recordingStartTime = Date()
            log("SFSpeech mode: recording...")
        } catch {
            log("engine failed: \(error)")
        }
    }

    // MARK: - Stop Recording

    private func stopRecording() {
        log("=== STOP ===")
        guard isRecording else { return }

        if isWhisperSession {
            // Whisper batch path — stop tap, then transcribe accumulated frames
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()

            // Show processing indicator (D-03) — isRecording stays true during transcription (Pitfall 6)
            lastTranscriptPreview = "Processing..."

            // Capture and clear accumulated frames
            let frames = whisperAudioFrames
            whisperAudioFrames = []

            Task {
                do {
                    let (text, lang) = try await whisperService.transcribe(frames)
                    await MainActor.run {
                        self.detectedLanguage = lang  // Phase 32 will use this
                        if !text.isEmpty && !self.hasSubmitted {
                            self.hasSubmitted = true
                            self.lastTranscriptPreview = text
                            self.injectAndSubmit(text)
                        }
                        // Engine replaced AFTER transcription completes (same pattern as Parakeet Bug 5 fix)
                        self.isRecording = false
                        self.audioEngine = AVAudioEngine()
                        self.log("Whisper transcription complete: lang=\(lang), '\(text)'")
                    }
                } catch {
                    self.log("Whisper transcription failed: \(error)")
                    await MainActor.run {
                        self.isRecording = false
                        self.audioEngine = AVAudioEngine()
                    }
                }
            }
        } else {
            // SFSpeech path — endAudio and wait for final result
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            isRecording = false
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

    // MARK: - Inject text + Enter (Whisper and SFSpeech paths)

    private func injectAndSubmit(_ text: String) {
        guard !text.isEmpty else { return }

        focusTerminal() // waits for activation notification (FRAG-01)

        // Verify terminal is actually frontmost before posting CGEvents (AUDIT-08)
        let frontBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        guard Self.terminalBundleIDs.contains(frontBundleID) else {
            log("Injection aborted — frontmost app '\(frontBundleID)' is not a terminal")
            return
        }

        let utf16 = Array(text.utf16)
        if utf16.count <= 200 {
            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
            keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            // Clear modifier flags so held Option key doesn't corrupt the injection
            keyDown.flags = []
            keyUp.flags = []
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        } else {
            // Clipboard paste fallback for long text
            let pb = NSPasteboard.general
            let old = pb.string(forType: .string)
            pb.clearContents()
            pb.setString(text, forType: .string)
            let afterWriteCount = pb.changeCount  // Capture AFTER our writes (AUDIT-07)
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else { return }
            down.flags = .maskCommand
            up.flags = .maskCommand
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            usleep(100_000)
            // Restore only if no external clipboard write occurred during paste window (AUDIT-07)
            if pb.changeCount == afterWriteCount {
                if let old { pb.clearContents(); pb.setString(old, forType: .string) }
            } else {
                log("Clipboard changed externally during injection — skipping restore")
            }
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

    /// Injects text into the terminal WITHOUT pressing Enter.
    /// Retained for potential future use (not used by Whisper batch path).
    private func injectTextOnly(_ text: String) {
        guard !text.isEmpty else { return }

        let utf16 = Array(text.utf16)
        if utf16.count <= 200 {
            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
            keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyDown.flags = []
            keyUp.flags = []
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        } else {
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

        log("injected (no submit): '\(text)'")
    }

    // MARK: - Terminal Focus

    /// Focus a terminal app and wait for it to become frontmost via NSWorkspace notification (FRAG-01).
    /// Returns true if terminal was successfully focused.
    @discardableResult
    private func focusTerminal() -> Bool {
        var targetApp: NSRunningApplication?
        for app in NSWorkspace.shared.runningApplications {
            guard let bid = app.bundleIdentifier, Self.terminalBundleIDs.contains(bid) else { continue }
            targetApp = app
            break
        }
        guard let app = targetApp else {
            log("no terminal found to focus")
            return false
        }

        // If already frontmost, no wait needed
        if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier {
            log("terminal already frontmost: \(app.bundleIdentifier ?? "")")
            return true
        }

        // Wait for activation via notification instead of usleep (FRAG-01)
        let semaphore = DispatchSemaphore(value: 0)
        let observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { notification in
            if let activated = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               activated.processIdentifier == app.processIdentifier {
                semaphore.signal()
            }
        }
        app.activate()
        // Wait up to 500ms for activation (generous but bounded)
        let result = semaphore.wait(timeout: .now() + 0.5)
        NSWorkspace.shared.notificationCenter.removeObserver(observer)

        if result == .timedOut {
            log("terminal focus timed out — proceeding anyway: \(app.bundleIdentifier ?? "")")
        } else {
            log("focused terminal via notification: \(app.bundleIdentifier ?? "")")
        }
        return true
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
