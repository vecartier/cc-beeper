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
    static let eventsFile = ipcDir + "/events.jsonl"
    static let pendingFile = ipcDir + "/pending.json"
    static let responseFile = ipcDir + "/response.json"

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
                // Guard against double-setup — restartFileWatcher handles cleanup
                restartFileWatcher()
                setupSummaryWatcher()
                setupGlobalHotkeys()
            } else {
                // Stop any active recording and TTS before tearing down
                voiceService.stopIfRecording()
                ttsService.stopSpeaking()
                // Tear down all monitoring
                source?.cancel(); source = nil
                try? fileHandle?.close(); fileHandle = nil
                summarySource?.cancel(); summarySource = nil
                idleWork?.cancel()
                // Remove hotkey monitors so keypresses don't fire when powered off
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

    /// Whether VoiceOver is enabled (reads summaries aloud when Claude finishes).
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

    // MARK: - Hotkey Bindings

    @Published var hotkeyAccept: UInt16 = 0 {   // kVK_ANSI_A
        didSet { UserDefaults.standard.set(Int(hotkeyAccept), forKey: "hotkeyAccept") }
    }
    @Published var hotkeyDeny: UInt16 = 2 {      // kVK_ANSI_D
        didSet { UserDefaults.standard.set(Int(hotkeyDeny), forKey: "hotkeyDeny") }
    }
    @Published var hotkeyVoice: UInt16 = 15 {     // kVK_ANSI_R
        didSet { UserDefaults.standard.set(Int(hotkeyVoice), forKey: "hotkeyVoice") }
    }
    @Published var hotkeyTerminal: UInt16 = 17 {  // kVK_ANSI_T
        didSet { UserDefaults.standard.set(Int(hotkeyTerminal), forKey: "hotkeyTerminal") }
    }
    @Published var hotkeyMute: UInt16 = 46 {     // kVK_ANSI_M
        didSet { UserDefaults.standard.set(Int(hotkeyMute), forKey: "hotkeyMute") }
    }

    /// Selected Kokoro voice identifier.
    @Published var kokoroVoice: String = "bm_daniel" {
        didSet {
            UserDefaults.standard.set(kokoroVoice, forKey: "kokoroVoice")
            ttsService.setKokoroVoice(kokoroVoice)
        }
    }

    private static let summaryFile = ipcDir + "/last_summary.txt"
    private var summarySource: DispatchSourceFileSystemObject?
    private var lastSummaryHash: Int = 0

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
        if autoAccept { return .yolo }
        if state.needsAttention { return .attention }
        return .normal
    }

    /// Per-session state tracking — key is session ID, value is last known state.
    private var sessionStates: [String: ClaudeState] = [:]

    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?
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
        rehydrateSessions()
        setupFileWatcher()
        setupSummaryWatcher()
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
        // Load saved hotkey bindings (defaults are the property initializers)
        if let v = UserDefaults.standard.object(forKey: "hotkeyAccept") as? Int { hotkeyAccept = UInt16(v) }
        if let v = UserDefaults.standard.object(forKey: "hotkeyDeny") as? Int { hotkeyDeny = UInt16(v) }
        if let v = UserDefaults.standard.object(forKey: "hotkeyVoice") as? Int { hotkeyVoice = UInt16(v) }
        if let v = UserDefaults.standard.object(forKey: "hotkeyTerminal") as? Int { hotkeyTerminal = UInt16(v) }
        if let v = UserDefaults.standard.object(forKey: "hotkeyMute") as? Int { hotkeyMute = UInt16(v) }
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
        // Pre-warm Parakeet model at launch (downloads + compiles on first run, cached after)
        Task {
            do {
                try await ParakeetService.shared.initialize()
            } catch {
                // Log to voice.log so we can see why it failed
                let line = "[\(Date())] Parakeet pre-warm failed: \(error)\n"
                let logPath = Self.ipcDir + "/voice.log"
                if let fh = FileHandle(forWritingAtPath: logPath) {
                    fh.seekToEndOfFile()
                    fh.write(line.data(using: .utf8)!)
                    fh.closeFile()
                }
            }
        }
        // Launch Kokoro TTS subprocess
        ttsService.launchKokoro()
    }

    /// Pre-populate sessionStates from sessions.json so the app picks up
    /// sessions that were already active before this launch.
    private func rehydrateSessions() {
        guard let data = FileManager.default.contents(atPath: Self.ipcDir + "/sessions.json"),
              let sessions = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let now = Int(Date().timeIntervalSince1970)
        for (sid, value) in sessions {
            // Only rehydrate sessions less than 2 hours old (matches hook's 7200s pruning)
            if let ts = value as? Int, now - ts < 7200 {
                sessionStates[sid] = .thinking
            }
        }
        if !sessionStates.isEmpty {
            state = .thinking
            sessionCount = sessionStates.count
        }
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
        source?.cancel()
        try? fileHandle?.close()
        summarySource?.cancel()
        ttsService.stopSpeaking()
        ttsService.shutdownKokoro()
        // idleWork and keyMonitors cleaned up via isActive.didSet
    }

    // MARK: Actions

    func respondToPermission(allow: Bool) {
        guard let pending = pendingPermission else {
            // Even without pending data, clear the awaiting flag
            awaitingUserAction = false
            state = allow ? .thinking : .finished
            return
        }
        let response: [String: Any] = ["id": pending.id, "decision": allow ? "allow" : "deny"]
        if let data = try? JSONSerialization.data(withJSONObject: response) {
            try? data.write(to: URL(fileURLWithPath: Self.responseFile))
        }
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

    // MARK: File Watcher

    private func setupFileWatcher() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: Self.eventsFile) {
            fm.createFile(atPath: Self.eventsFile, contents: nil)
        }
        guard let fh = FileHandle(forReadingAtPath: Self.eventsFile) else { return }
        fh.seekToEndOfFile()
        self.fileHandle = fh

        let fd = open(Self.eventsFile, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .delete, .rename], queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                self.restartFileWatcher()
                return
            }
            self.readNewEvents()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        self.source = source
    }

    private func restartFileWatcher() {
        source?.cancel()
        source = nil
        try? fileHandle?.close()
        fileHandle = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self?.setupFileWatcher()
        }
    }

    // MARK: Summary File Watcher

    private func setupSummaryWatcher() {
        // Cancel existing watcher before creating a new one
        summarySource?.cancel()
        summarySource = nil

        let fm = FileManager.default
        if !fm.fileExists(atPath: Self.summaryFile) {
            fm.createFile(atPath: Self.summaryFile, contents: nil)
        }
        if let data = fm.contents(atPath: Self.summaryFile) {
            lastSummaryHash = data.hashValue
        }

        let fd = open(Self.summaryFile, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .rename, .delete], queue: .main
        )
        source.setEventHandler { [weak self] in self?.onSummaryFileChanged() }
        source.setCancelHandler { close(fd) }
        source.resume()
        self.summarySource = source
    }

    private func onSummaryFileChanged() {
        guard let data = FileManager.default.contents(atPath: Self.summaryFile),
              let text = String(data: data, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let hash = data.hashValue
        guard hash != lastSummaryHash else { return }
        lastSummaryHash = hash

        // NEVER interrupt recording — recording has absolute priority
        guard voiceOver, !isRecording else { return }

        Task {
            let summary = await ttsService.speakSummary(text, provider: self.ttsProvider)
            await MainActor.run {
                // Re-check after async summarization — user might have started recording
                guard !self.isRecording else { return }
                self.lastSummary = summary
            }
        }
    }

    private func readNewEvents() {
        guard let fh = fileHandle else { return }
        let data = fh.availableData
        guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
        for line in text.split(separator: "\n") { processEvent(String(line)) }
    }

    private func processEvent(_ json: String) {
        guard let data = json.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["event"] as? String,
              event["sid"] is String,
              event["ts"] is Int else { return }

        let sid = event["sid"] as? String ?? ""

        // Permission — only trigger needsYou if pending.json has fresh data for a real tool
        if type == "permission" || (type == "notification" && event["type"] as? String == "permission_prompt") {
            // Check if pending.json exists and is fresh (less than 5 seconds old)
            let fm = FileManager.default
            guard let attrs = try? fm.attributesOfItem(atPath: Self.pendingFile),
                  let modDate = attrs[.modificationDate] as? Date,
                  Date().timeIntervalSince(modDate) < 5,
                  let data = fm.contents(atPath: Self.pendingFile),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["id"] is String else {
                // No fresh pending permission — this was likely auto-approved by Claude Code
                return
            }

            // Ignore interactive-but-safe tools (not real permissions)
            let safeTool = (json["tool"] as? String ?? "").lowercased()
            let ignoredTools = ["taskcreate", "taskupdate", "taskget", "tasklist"]
            if ignoredTools.contains(safeTool) { return }

            idleWork?.cancel()
            let tool = json["tool"] as? String ?? ""
            let summary = json["summary"] as? String ?? tool.lowercased()
            pendingPermission = PendingPermission(id: json["id"] as? String ?? "", tool: tool, summary: summary)
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
        if awaitingUserAction && (type == "pre_tool" || type == "post_tool" || type == "stop" || type == "session_end") {
            let fm = FileManager.default
            let pendingGone = !fm.fileExists(atPath: Self.pendingFile)
            let responseExists = fm.fileExists(atPath: Self.responseFile)
            // Clear if: pending.json gone, response.json exists, OR Claude moved on
            // (pre_tool/post_tool means Claude got approval from somewhere — terminal or timeout)
            if pendingGone || responseExists || type == "pre_tool" || type == "post_tool" {
                awaitingUserAction = false
                pendingPermission = nil
                // Clean up stale files
                try? fm.removeItem(atPath: Self.pendingFile)
                try? fm.removeItem(atPath: Self.responseFile)
            }
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
        // Prune sessions no longer tracked by the hook (at most every 30 seconds)
        if Date().timeIntervalSince(lastPruneTime) > 30 {
            if let sessionsData = FileManager.default.contents(atPath: Self.ipcDir + "/sessions.json"),
               let sessions = try? JSONSerialization.jsonObject(with: sessionsData) as? [String: Any] {
                let activeIds = Set(sessions.keys)
                for key in sessionStates.keys where !activeIds.contains(key) {
                    sessionStates.removeValue(forKey: key)
                }
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

    // MARK: Pending Permission

    private func loadPendingPermission(retries: Int = 5) {
        guard let data = FileManager.default.contents(atPath: Self.pendingFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String else {
            if retries > 0 {
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    self?.loadPendingPermission(retries: retries - 1)
                }
            }
            return
        }
        let tool = json["tool"] as? String ?? ""
        let summary = json["summary"] as? String ?? tool.lowercased()
        pendingPermission = PendingPermission(id: id, tool: tool, summary: summary)
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

        // Register Carbon hotkeys — these CONSUME the event, no leaking to focused app
        func registerHotKey(keyCode: UInt16, handler: @escaping () -> Void) {
            let key = Key(carbonKeyCode: UInt32(keyCode))!
            let hk = HotKey(key: key, modifiers: [.option])
            hk.keyDownHandler = handler
            carbonHotKeys.append(hk)
        }

        registerHotKey(keyCode: hotkeyAccept) { [weak self] in
            guard let self, self.pendingPermission != nil else { return }
            Task { @MainActor in self.respondToPermission(allow: true) }
        }
        registerHotKey(keyCode: hotkeyDeny) { [weak self] in
            guard let self, self.pendingPermission != nil else { return }
            Task { @MainActor in self.respondToPermission(allow: false) }
        }
        registerHotKey(keyCode: hotkeyVoice) { [weak self] in
            Task { @MainActor in self?.voiceService.toggle() }
        }
        registerHotKey(keyCode: hotkeyTerminal) { [weak self] in
            Task { @MainActor in self?.goToConversation() }
        }
        registerHotKey(keyCode: hotkeyMute) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                print("[CC-Beeper] mute hotkey pressed — isSpeaking=\(self.ttsService.isSpeaking)")
                if self.ttsService.isSpeaking {
                    self.ttsService.stopSpeaking()
                } else {
                    self.triggerSummary()
                }
            }
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
