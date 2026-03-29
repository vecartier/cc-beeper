import Foundation
import Combine
import AppKit
import ApplicationServices
import HotKey
import Carbon.HIToolbox

// MARK: - State

enum ClaudeState: Equatable {
    case thinking
    case finished
    case needsYou
    case idle

    var label: String {
        switch self {
        case .thinking: "THINKING..."
        case .finished: "DONE!"
        case .needsYou: "NEEDS YOU!"
        case .idle: "ZZZ..."
        }
    }

    var needsAttention: Bool { self == .needsYou }
    var canGoToConvo: Bool { self == .finished }
}

// MARK: - Pending Permission

struct PendingPermission: Equatable {
    let id: String
    let tool: String
    let summary: String
}

// MARK: - Monitor

@MainActor
final class ClaudeMonitor: ObservableObject {
    static let ipcDir = NSHomeDirectory() + "/.claude/cc-beeper"

    @Published var state: ClaudeState = .finished
    @Published var pendingPermission: PendingPermission?
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var autoAccept: Bool {
        didSet { UserDefaults.standard.set(autoAccept, forKey: "autoAccept") }
    }
    @Published var vibrationEnabled: Bool {
        didSet { UserDefaults.standard.set(vibrationEnabled, forKey: "vibrationEnabled") }
    }
    @Published var sessionCount: Int = 0

    /// Controls whether the widget is active. False = hidden + monitoring stopped.
    @Published var isActive: Bool = true {
        didSet {
            UserDefaults.standard.set(isActive, forKey: "isActive")
            if isActive {
                httpServer.start { [weak self] payload in
                    guard let self else { return nil }
                    return self.handleHookPayload(payload)
                }
                setupGlobalHotkeys()
            } else {
                // Stop any active recording and TTS before tearing down
                voiceService.stopIfRecording()
                ttsService.stopSpeaking()
                httpServer.stop()
                idleWork?.cancel()
                carbonHotKeys.removeAll()
                if let m = localKeyMonitor { NSEvent.removeMonitor(m); localKeyMonitor = nil }
                state = .idle
                pendingPermission = nil
                awaitingUserAction = false
            }
        }
    }

    /// When THINKING started — drives elapsed time display.
    @Published var thinkingStartTime: Date? = nil

    /// Current tool name being used — populated from pre_tool/post_tool events.
    @Published var currentTool: String? = nil

    /// Last summary text (Phase 11 populates; shows "Done" if nil).
    @Published var lastSummary: String? = nil

    /// Whether voice is recording — mirrored from VoiceService via Combine (read-only outside ClaudeMonitor).
    @Published private(set) var isRecording: Bool = false

    /// Whether TTS is speaking — mirrored from TTSService via Combine (read-only outside ClaudeMonitor).
    @Published private(set) var isSpeaking: Bool = false

    let voiceService = VoiceService()
    let ttsService = TTSService()

    /// Whether Read Over is enabled (reads summaries aloud when Claude finishes).
    @Published var voiceOver: Bool = false {
        didSet { UserDefaults.standard.set(voiceOver, forKey: "voiceOver") }
    }

    /// TTS provider selection: "kokoro" (local, default), "apple" (fallback).
    @Published var ttsProvider: String = "kokoro" {
        didSet { UserDefaults.standard.set(ttsProvider, forKey: "ttsProvider") }
    }

    /// Selected PocketTTS voice identifier (legacy, kept for migration).
    @Published var pocketttsVoice: String = "alba" {
        didSet {
            UserDefaults.standard.set(pocketttsVoice, forKey: "pocketttsVoice")
            Task { await PocketTTSService.shared.setDefaultVoice(pocketttsVoice) }
        }
    }

    // MARK: - Hotkey Bindings (stored as characters, layout-independent)

    @Published var hotkeyAccept: String = "A" {
        didSet { UserDefaults.standard.set(hotkeyAccept, forKey: "hotkeyChar_accept"); setupGlobalHotkeys() }
    }
    @Published var hotkeyDeny: String = "D" {
        didSet { UserDefaults.standard.set(hotkeyDeny, forKey: "hotkeyChar_deny"); setupGlobalHotkeys() }
    }
    @Published var hotkeyVoice: String = "R" {
        didSet { UserDefaults.standard.set(hotkeyVoice, forKey: "hotkeyChar_voice"); setupGlobalHotkeys() }
    }
    @Published var hotkeyTerminal: String = "T" {
        didSet { UserDefaults.standard.set(hotkeyTerminal, forKey: "hotkeyChar_terminal"); setupGlobalHotkeys() }
    }
    @Published var hotkeyMute: String = "M" {
        didSet { UserDefaults.standard.set(hotkeyMute, forKey: "hotkeyChar_mute"); setupGlobalHotkeys() }
    }

    /// Selected Whisper model size: "small" (default) or "medium".
    @Published var whisperModelSize: String = "small" {
        didSet { UserDefaults.standard.set(whisperModelSize, forKey: "whisperModelSize") }
    }

    /// Selected Kokoro voice identifier.
    @Published var kokoroVoice: String = "bm_daniel" {
        didSet {
            UserDefaults.standard.set(kokoroVoice, forKey: "kokoroVoice")
            ttsService.setKokoroVoice(kokoroVoice)
        }
    }

    /// Selected Kokoro language code. Default 'a' (American English) per D-03.
    @Published var kokoroLangCode: String = "a" {
        didSet {
            UserDefaults.standard.set(kokoroLangCode, forKey: "kokoroLangCode")
            ttsService.setKokoroLangCode(kokoroLangCode)
            // Auto-select first valid voice for new language (per D-06)
            if !KokoroVoiceCatalog.isVoiceValid(kokoroVoice, for: kokoroLangCode) {
                kokoroVoice = KokoroVoiceCatalog.defaultVoice(for: kokoroLangCode)
            }
            // Update dep requirement flag (per LANG-03)
            depsNeededForCurrentLang = KokoroVoiceCatalog.langCodesRequiringDeps.contains(kokoroLangCode)
        }
    }

    /// True when the current language requires extra pip dependencies (Japanese, Chinese).
    /// Observed by Settings and onboarding to show install prompt. NOT auto-installed — UI-triggered only.
    @Published var depsNeededForCurrentLang: Bool = false

    /// Computed: seconds elapsed since thinking started.
    var elapsedSeconds: Int {
        guard let start = thinkingStartTime else { return 0 }
        return Int(Date().timeIntervalSince(start))
    }

    /// True when a permission has been requested and user hasn't acted yet.
    /// This is the source of truth — never cleared by timeouts or external events.
    private var awaitingUserAction = false

    var menuBarIconState: BeeperIconState {
        if !isActive { return .hidden }
        // Show recording/speaking icons only when widget is hidden
        if !CCBeeperApp.isMainWindowVisible() {
            if isRecording { return .recording }
            if ttsService.isSpeaking { return .speaking }
        }
        if autoAccept { return .yolo }
        if state.needsAttention { return .attention }
        return .normal
    }

    /// Per-session state tracking — key is session ID, value is last known state.
    private var sessionStates: [String: ClaudeState] = [:]

    /// Last-seen timestamps per session — used for age-based pruning (no sessions.json needed).
    private var sessionLastSeen: [String: Date] = [:]

    private let httpServer = HTTPHookServer()
    private var idleWork: DispatchWorkItem?
    private var lastPruneTime: Date = .distantPast
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    // Carbon hotkeys (consume the event — no leaking to focused app)
    private var carbonHotKeys: [Any] = []

    init() {
        soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        autoAccept = UserDefaults.standard.object(forKey: "autoAccept") as? Bool ?? false
        vibrationEnabled = UserDefaults.standard.object(forKey: "vibrationEnabled") as? Bool ?? true
        ensureIPCDir()
        httpServer.start { [weak self] payload in
            guard let self else { return nil }
            return self.handleHookPayload(payload)
        }
        setupGlobalHotkeys()
        // Set after watcher is running so didSet fires only on external mutation
        // Migrate legacy "autoSpeak" key to "voiceOver"
        if UserDefaults.standard.object(forKey: "voiceOver") == nil,
           let legacy = UserDefaults.standard.object(forKey: "autoSpeak") as? Bool {
            UserDefaults.standard.set(legacy, forKey: "voiceOver")
            UserDefaults.standard.removeObject(forKey: "autoSpeak")
        }
        voiceOver = UserDefaults.standard.bool(forKey: "voiceOver")
        ttsProvider = UserDefaults.standard.string(forKey: "ttsProvider") ?? "kokoro"
        pocketttsVoice = UserDefaults.standard.string(forKey: "pocketttsVoice") ?? "alba"
        kokoroVoice = UserDefaults.standard.string(forKey: "kokoroVoice") ?? "bm_daniel"
        kokoroLangCode = UserDefaults.standard.string(forKey: "kokoroLangCode") ?? "a"
        // First-launch: set language from macOS system language (per LANG-02)
        // Use object(forKey:) not string(forKey:) — returns nil ONLY when key was never set
        if UserDefaults.standard.object(forKey: "kokoroLangCode") == nil {
            let systemLocale = Locale.preferredLanguages.first ?? "en"
            let detectedCode = KokoroVoiceCatalog.kokoroLangCode(fromSystemLocale: systemLocale) ?? "a"
            kokoroLangCode = detectedCode  // triggers didSet → sends to TTSService + VoiceService
        }
        // Initialize dep flag for current language
        depsNeededForCurrentLang = KokoroVoiceCatalog.langCodesRequiringDeps.contains(kokoroLangCode)
        whisperModelSize = UserDefaults.standard.string(forKey: "whisperModelSize") ?? "small"
        // Load saved hotkey bindings (character-based, layout-independent)
        // Migrate from old keyCode-based storage if present
        migrateHotkeyDefaults()
        if let v = UserDefaults.standard.string(forKey: "hotkeyChar_accept") { hotkeyAccept = v }
        if let v = UserDefaults.standard.string(forKey: "hotkeyChar_deny") { hotkeyDeny = v }
        if let v = UserDefaults.standard.string(forKey: "hotkeyChar_voice") { hotkeyVoice = v }
        if let v = UserDefaults.standard.string(forKey: "hotkeyChar_terminal") { hotkeyTerminal = v }
        if let v = UserDefaults.standard.string(forKey: "hotkeyChar_mute") { hotkeyMute = v }
        isActive = UserDefaults.standard.object(forKey: "isActive") as? Bool ?? true
        // Wire ttsService into voiceService so recording cuts TTS
        voiceService.ttsService = ttsService
        // Mirror VoiceService.isRecording into ClaudeMonitor.isRecording for UI binding
        voiceService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)
        // Mirror TTSService.isSpeaking into ClaudeMonitor.isSpeaking for UI binding
        ttsService.$isSpeaking
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSpeaking)
        // Pre-warm Whisper model at launch — loads from cache, falls back to SFSpeech if not downloaded
        Task {
            guard WhisperService.modelsDownloaded else { return }
            do {
                let size = WhisperModelSize(rawValue: self.whisperModelSize) ?? .small
                try await WhisperService.shared.initialize(size: size)
            } catch {
                // Log to voice.log so we can see why it failed
                let line = "[\(Date())] Whisper pre-warm failed: \(error)\n"
                let logPath = Self.ipcDir + "/voice.log"
                if let fh = FileHandle(forWritingAtPath: logPath) {
                    fh.seekToEndOfFile()
                    fh.write(line.data(using: .utf8)!)
                    fh.closeFile()
                }
            }
        }
        // Launch Kokoro TTS subprocess
        ttsService.onKokoroReady = { [weak self] in
            guard let self else { return }
            // Send saved lang code + voice after subprocess is ready
            self.ttsService.setKokoroLangCode(self.kokoroLangCode)
            self.ttsService.setKokoroVoice(self.kokoroVoice)
        }
        ttsService.launchKokoro()
    }

    private func ensureIPCDir() {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: Self.ipcDir, isDirectory: &isDir) || !isDir.boolValue {
            try? fm.createDirectory(atPath: Self.ipcDir, withIntermediateDirectories: true)
        }
        // Ensure owner-only permissions (0700)
        try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: Self.ipcDir)
    }

    nonisolated func cleanup() {
        // Called from deinit — captures are done safely via nonisolated
    }

    deinit {
        ttsService.stopSpeaking()
        ttsService.shutdownKokoro()
        // HTTPHookServer.stop() is @MainActor — called via applicationWillTerminate in AppDelegate
        // The port file is also cleaned up by the OS on process exit
    }

    // MARK: - HTTP Hook Handler

    /// Translates HTTP hook payloads into the existing JSONL event format
    /// and routes to processEvent(). Returns nil for async hooks.
    /// For permission_prompt Notifications, returns a sentinel (handled by HTTPHookServer).
    private func handleHookPayload(_ payload: [String: Any]) -> [String: Any]? {
        guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
        let sessionId = payload["session_id"] as? String ?? ""
        let toolName = payload["tool_name"] as? String
        let ts = Int(Date().timeIntervalSince1970)

        // Translate hook_event_name to existing event types
        let eventType: String
        switch hookEventName {
        case "PreToolUse":
            eventType = "pre_tool"
        case "PostToolUse":
            eventType = "post_tool"
        case "Notification":
            // Check notification sub-type
            let notificationType = payload["notification_type"] as? String ?? ""
            if notificationType == "permission_prompt" {
                // Build synthetic JSONL event with permission type marker
                var syntheticEvent: [String: Any] = [
                    "event": "notification",
                    "type": "permission_prompt",
                    "sid": sessionId,
                    "ts": ts,
                ]
                if let message = payload["message"] as? String {
                    syntheticEvent["summary"] = message
                }
                if let tool = toolName {
                    syntheticEvent["tool"] = tool
                }
                let json = (try? JSONSerialization.data(withJSONObject: syntheticEvent))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                processEvent(json)
                // Return a sentinel dict so HTTPHookServer knows to hold the connection
                return ["_hold_connection": true]
            } else {
                // Non-permission notifications (auth_success, idle_prompt, etc.)
                // Process as generic notification — state machine ignores unknown types
                eventType = "notification"
            }
        case "Stop":
            eventType = "stop"
            // Extract TTS summary from last_assistant_message (per D-05, HTTP-04)
            if let summary = payload["last_assistant_message"] as? String, !summary.isEmpty {
                // NEVER interrupt recording — recording has absolute priority
                if voiceOver && !isRecording {
                    Task { [weak self] in
                        guard let self else { return }
                        let spoken = await self.ttsService.speakSummary(summary, provider: self.ttsProvider)
                        await MainActor.run {
                            guard !self.isRecording else { return }
                            self.lastSummary = spoken
                        }
                    }
                } else {
                    lastSummary = summary
                }
            } else {
                // Log missing last_assistant_message per D-05
                let logPath = Self.ipcDir + "/voice.log"
                let logEntry = "[\(ISO8601DateFormatter().string(from: Date()))] Stop event missing last_assistant_message for session \(sessionId)\n"
                if let logData = logEntry.data(using: .utf8) {
                    if FileManager.default.fileExists(atPath: logPath) {
                        if let fh = FileHandle(forWritingAtPath: logPath) {
                            fh.seekToEndOfFile()
                            fh.write(logData)
                            try? fh.close()
                        }
                    } else {
                        try? logData.write(to: URL(fileURLWithPath: logPath))
                    }
                }
            }
        case "StopFailure":
            eventType = "stop" // StopFailure maps to stop (error context is Phase 36 LCD-04)
        default:
            return nil // Unknown event — ignore
        }

        // Build synthetic JSONL event matching existing processEvent format
        var syntheticEvent: [String: Any] = [
            "event": eventType,
            "sid": sessionId,
            "ts": ts,
        ]
        if let tool = toolName {
            syntheticEvent["tool"] = tool
        }

        if let json = try? JSONSerialization.data(withJSONObject: syntheticEvent),
           let jsonStr = String(data: json, encoding: .utf8) {
            processEvent(jsonStr)
        }

        return nil // Async — respond immediately with 200
    }

    // MARK: Actions

    func respondToPermission(allow: Bool) {
        let response: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "Notification",
                "decision": allow ? "allow" : "deny",
                "updatedPermissions": allow
                    ? ["allow": true, "reason": "Approved via CC-Beeper"]
                    : ["deny": true, "reason": "Denied via CC-Beeper"]
            ]
        ]
        httpServer.sendPermissionResponse(response)

        pendingPermission = nil
        awaitingUserAction = false
        state = allow ? .thinking : .finished
    }

    func goToConversation() {
        activateTerminal()
    }

    func triggerSummary() {
        guard let text = lastSummary, !text.isEmpty, !ttsService.isSpeaking else { return }
        Task {
            await ttsService.speakSummary(text, provider: ttsProvider)
        }
    }

    private func activateTerminal() {
        let ids = [
            "com.apple.Terminal", "com.googlecode.iterm2",
            "dev.warp.Warp-Stable", "io.alacritty",
            "net.kovidgoyal.kitty", "com.github.wez.wezterm",
        ]
        for app in NSWorkspace.shared.runningApplications {
            if let bid = app.bundleIdentifier, ids.contains(bid) {
                app.activate()
                return
            }
        }
    }

    private func processEvent(_ json: String) {
        guard let data = json.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["event"] as? String,
              event["sid"] is String,
              event["ts"] is Int else { return }

        let sid = event["sid"] as? String ?? ""

        // Update last-seen time for this session (for age-based pruning)
        if !sid.isEmpty {
            sessionLastSeen[sid] = Date()
        }

        // Permission — trigger needsYou from synthetic event carrying permission details
        if type == "notification" && event["type"] as? String == "permission_prompt" {
            idleWork?.cancel()
            let tool = event["tool"] as? String ?? ""
            let summary = event["summary"] as? String ?? tool.lowercased()
            // Use sessionId as the permission ID (no more pending.json ID)
            pendingPermission = PendingPermission(id: sid, tool: tool, summary: summary)
            setupGlobalHotkeys()

            if autoAccept {
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    self?.respondToPermission(allow: true)
                }
            } else {
                if !sid.isEmpty { sessionStates[sid] = .needsYou }
                sessionCount = sessionStates.count
                awaitingUserAction = true
                thinkingStartTime = Date() // Reset timer for each new permission/question
                state = .needsYou
                playAlert()
            }
            return
        }
        if type == "permission_timeout" {
            return
        }

        // If we're awaiting user action but Claude is working again,
        // the permission was resolved elsewhere (user accepted in terminal, or hook timed out).
        if awaitingUserAction && (type == "pre_tool" || type == "post_tool" || type == "stop") {
            // Claude moved on — permission was resolved elsewhere (terminal or timeout)
            awaitingUserAction = false
            pendingPermission = nil
            httpServer.permissionConnection?.cancel()
            // No more pending.json/response.json cleanup needed
        }

        idleWork?.cancel()

        switch type {
        case "pre_tool", "post_tool":
            let tool = event["tool"] as? String
            if let tool { currentTool = tool }
            // Only reset thinkingStartTime when transitioning INTO thinking
            if sessionStates[sid] != .thinking {
                thinkingStartTime = Date()
            }
            if !sid.isEmpty { sessionStates[sid] = .thinking }
            updateAggregateState()
        case "post_tool_error":
            if !sid.isEmpty { sessionStates[sid] = .thinking }
            updateAggregateState()
        case "stop":
            if !sid.isEmpty { sessionStates[sid] = .finished }
            thinkingStartTime = nil
            currentTool = nil
            updateAggregateState()
            if state == .finished {
                if !autoAccept { playDoneChime() }
                startIdleTimer(interval: 60)
            }
        case "session_start":
            if !sid.isEmpty { sessionStates[sid] = .thinking }
            updateAggregateState()
        case "session_end":
            if !sid.isEmpty { sessionStates.removeValue(forKey: sid) }
            lastPruneTime = .distantPast
            updateAggregateState()
        default:
            break
        }
    }

    /// Derive the overall state from all active sessions.
    /// Priority: needsYou > thinking > finished.
    private func updateAggregateState() {
        // Prune sessions not seen for 2 hours (replaces sessions.json-based pruning)
        if Date().timeIntervalSince(lastPruneTime) > 30 {
            let cutoff = Date().addingTimeInterval(-7200) // 2 hours
            for (sid, lastSeen) in sessionLastSeen where lastSeen < cutoff {
                sessionStates.removeValue(forKey: sid)
                sessionLastSeen.removeValue(forKey: sid)
            }
            lastPruneTime = Date()
        }

        // If we're still awaiting user action on a permission, keep needsYou
        // regardless of what individual session states say — the permission is real.
        if awaitingUserAction && pendingPermission != nil {
            state = .needsYou
            return
        }

        let values = sessionStates.values
        if values.contains(.needsYou) {
            state = .needsYou
        } else if values.contains(.thinking) {
            state = .thinking
        } else {
            state = .finished
        }
        sessionCount = sessionStates.count
    }

    // MARK: Timers & Sound

    private func startIdleTimer(interval: TimeInterval) {
        idleWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.pendingPermission == nil else { return }
            Task { @MainActor [weak self] in self?.state = .idle }
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: work)
    }

    private func setupGlobalHotkeys() {
        // Remove old Carbon hotkeys before re-registering
        carbonHotKeys.removeAll()

        // Debug: write hotkey registration to a file we can check
        let debugPath = Self.ipcDir + "/hotkeys-debug.txt"
        var debugLog = "setupGlobalHotkeys called at \(Date())\n"
        debugLog += "accept=\(hotkeyAccept) deny=\(hotkeyDeny) voice=\(hotkeyVoice) terminal=\(hotkeyTerminal) mute=\(hotkeyMute)\n"

        // Register Carbon hotkeys — resolve character to physical keyCode via current layout
        func registerHotKey(character: String, label: String, handler: @escaping () -> Void) {
            guard let keyCode = keyCodeForCharacter(character) else {
                debugLog += "FAILED: \(label) — no keyCode for '\(character)' on current layout\n"
                try? debugLog.write(toFile: debugPath, atomically: true, encoding: .utf8)
                ttsService.log("Hotkey FAILED: \(label) — no keyCode for '\(character)' on current layout")
                return
            }
            guard let key = Key(carbonKeyCode: UInt32(keyCode)) else {
                debugLog += "FAILED: \(label) — Key(carbonKeyCode: \(keyCode)) returned nil\n"
                try? debugLog.write(toFile: debugPath, atomically: true, encoding: .utf8)
                ttsService.log("Hotkey FAILED: \(label) — Key(carbonKeyCode: \(keyCode)) returned nil")
                return
            }
            let hk = HotKey(key: key, modifiers: [.option])
            hk.keyDownHandler = handler
            carbonHotKeys.append(hk)
            debugLog += "OK: \(label) — char='\(character)', keyCode=\(keyCode)\n"
        }

        registerHotKey(character: hotkeyAccept, label: "Accept") { [weak self] in
            guard let self, self.pendingPermission != nil else { return }
            Task { @MainActor in self.respondToPermission(allow: true) }
        }
        registerHotKey(character: hotkeyDeny, label: "Deny") { [weak self] in
            guard let self, self.pendingPermission != nil else { return }
            Task { @MainActor in self.respondToPermission(allow: false) }
        }
        registerHotKey(character: hotkeyVoice, label: "Voice") { [weak self] in
            Task { @MainActor in self?.voiceService.toggle() }
        }
        registerHotKey(character: hotkeyTerminal, label: "Terminal") { [weak self] in
            Task { @MainActor in self?.goToConversation() }
        }
        registerHotKey(character: hotkeyMute, label: "Mute") { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.ttsService.log("Mute hotkey pressed — isSpeaking=\(self.ttsService.isSpeaking)")
                if self.ttsService.isSpeaking {
                    self.ttsService.stopSpeaking()
                } else {
                    self.triggerSummary()
                }
            }
        }

        try? debugLog.write(toFile: debugPath, atomically: true, encoding: .utf8)
    }

    /// Migrate old keyCode-based hotkey defaults to character-based.
    /// Runs once — clears old keys after migration.
    private func migrateHotkeyDefaults() {
        guard UserDefaults.standard.string(forKey: "hotkeyChar_accept") == nil,
              UserDefaults.standard.object(forKey: "hotkeyAccept") != nil else { return }

        let oldKeys: [(old: String, new: String, fallback: String)] = [
            ("hotkeyAccept", "hotkeyChar_accept", "A"),
            ("hotkeyDeny", "hotkeyChar_deny", "D"),
            ("hotkeyVoice", "hotkeyChar_voice", "R"),
            ("hotkeyTerminal", "hotkeyChar_terminal", "T"),
            ("hotkeyMute", "hotkeyChar_mute", "M"),
        ]
        for entry in oldKeys {
            if let code = UserDefaults.standard.object(forKey: entry.old) as? Int {
                let char = characterForKeyCode(UInt16(code))
                UserDefaults.standard.set(char == "?" ? entry.fallback : char, forKey: entry.new)
            }
            UserDefaults.standard.removeObject(forKey: entry.old)
        }
    }

    private func playAlert() {
        guard soundEnabled else { return }
        NSSound(named: "Ping")?.play()
    }

    private func playDoneChime() {
        guard soundEnabled else { return }
        NSSound(named: "Pop")?.play()
    }
}
