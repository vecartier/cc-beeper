import Foundation
import Combine
import AppKit

// MARK: - State

enum ClaudeState: Equatable {
    case thinking
    case finished
    case needsYou

    var label: String {
        switch self {
        case .thinking: "THINKING..."
        case .finished: "DONE!"
        case .needsYou: "NEEDS YOU!"
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

final class ClaudeMonitor: ObservableObject {
    static let ipcDir = NSHomeDirectory() + "/.claude/claumagotchi"
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

    /// True when a permission has been requested and user hasn't acted yet.
    /// This is the source of truth — never cleared by timeouts or external events.
    private var awaitingUserAction = false

    /// Per-session state tracking — key is session ID, value is last known state.
    private var sessionStates: [String: ClaudeState] = [:]

    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?
    private var idleTimer: Timer?

    init() {
        soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        autoAccept = UserDefaults.standard.object(forKey: "autoAccept") as? Bool ?? false
        ensureIPCDir()
        setupFileWatcher()
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

    deinit {
        source?.cancel()
        try? fileHandle?.close()
        idleTimer?.invalidate()
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
        idleTimer?.invalidate()
        pendingPermission = nil
        awaitingUserAction = false
        state = .finished
        activateTerminal()
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
            fileDescriptor: fd, eventMask: [.write, .extend], queue: .main
        )
        source.setEventHandler { [weak self] in self?.readNewEvents() }
        source.setCancelHandler { close(fd) }
        source.resume()
        self.source = source
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
              let type = event["event"] as? String else { return }

        let sid = event["sid"] as? String ?? ""

        // Permission ALWAYS wins
        if type == "permission" {
            idleTimer?.invalidate()
            loadPendingPermission()
            if autoAccept {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.respondToPermission(allow: true)
                }
            } else {
                if !sid.isEmpty { sessionStates[sid] = .needsYou }
                awaitingUserAction = true
                state = .needsYou
                playAlert()
            }
            return
        }
        if type == "notification", event["type"] as? String == "permission_prompt" {
            idleTimer?.invalidate()
            loadPendingPermission()
            if autoAccept {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.respondToPermission(allow: true)
                }
            } else {
                if !sid.isEmpty { sessionStates[sid] = .needsYou }
                awaitingUserAction = true
                state = .needsYou
                playAlert()
            }
            return
        }
        if type == "permission_timeout" {
            return
        }

        // Awaiting user action -> nothing else changes display
        guard !awaitingUserAction else { return }

        idleTimer?.invalidate()

        switch type {
        case "pre_tool", "post_tool", "post_tool_error":
            if !sid.isEmpty { sessionStates[sid] = .thinking }
            updateAggregateState()
        case "stop":
            if !sid.isEmpty { sessionStates[sid] = .finished }
            updateAggregateState()
            if state == .finished {
                playDoneChime()
                startIdleTimer(interval: 60)
            }
        case "session_start":
            if !sid.isEmpty { sessionStates[sid] = .thinking }
            updateAggregateState()
        case "session_end":
            if !sid.isEmpty { sessionStates.removeValue(forKey: sid) }
            updateAggregateState()
        default:
            break
        }
    }

    /// Derive the overall state from all active sessions.
    /// Priority: needsYou > thinking > finished.
    private func updateAggregateState() {
        // Prune sessions no longer tracked by the hook
        if let sessionsData = FileManager.default.contents(atPath: Self.ipcDir + "/sessions.json"),
           let sessions = try? JSONSerialization.jsonObject(with: sessionsData) as? [String: Any] {
            let activeIds = Set(sessions.keys)
            for key in sessionStates.keys where !activeIds.contains(key) {
                sessionStates.removeValue(forKey: key)
            }
        }

        let values = sessionStates.values
        if values.contains(.needsYou) {
            state = .needsYou
        } else if values.contains(.thinking) {
            state = .thinking
        } else {
            state = .finished
        }
    }

    // MARK: Pending Permission

    private func loadPendingPermission(retries: Int = 5) {
        guard let data = FileManager.default.contents(atPath: Self.pendingFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String else {
            if retries > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
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
        idleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self, self.pendingPermission == nil else { return }
            self.state = .finished
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
