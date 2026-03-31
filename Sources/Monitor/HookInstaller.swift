import Foundation

struct HookInstaller {
    static let hooksDir    = NSHomeDirectory() + "/.claude/hooks"
    static let ipcDir      = NSHomeDirectory() + "/.claude/cc-beeper"
    static let settingsPath = NSHomeDirectory() + "/.claude/settings.json"

    /// Marker string for identifying CC-Beeper hooks in settings.json.
    /// Matching `cc-beeper/port` distinguishes HTTP hooks from old Python hooks.
    static let hookMarker = "cc-beeper/port"

    /// Base curl command for async monitoring hooks (PreToolUse, PostToolUse, Stop, StopFailure).
    /// Reads port file, pipes stdin JSON to CC-Beeper's HTTP endpoint.
    /// -s: silent mode (no progress), -o /dev/null: suppress response body,
    /// --max-time 3: fail fast if server unresponsive, || true: never fail the hook.
    private static let asyncCommand = "PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true"

    /// Blocking curl command for Notification and PermissionRequest hooks (per D-01, D-02).
    /// Notification is blocking because modern Claude Code routes permission_prompt via
    /// Notification with notification_type: "permission_prompt" (RESEARCH.md Pitfall 5).
    /// PermissionRequest is kept as a blocking safety net for older Claude Code versions.
    /// Non-permission Notifications get an immediate 200 from CC-Beeper (no delay for Claude Code).
    /// No -o /dev/null: stdout carries the hookSpecificOutput response back to Claude Code.
    /// No || true: if CC-Beeper isn't running, curl fails and Claude Code shows terminal prompt.
    /// --max-time 55: client-side timeout (hook timeout is 60 seconds).
    private static let blockingCommand = "PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222) && curl -s -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 55"

    /// Returns true when settings.json contains at least one hook entry
    /// whose command references cc-beeper/port (HTTP hooks).
    static var isInstalled: Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsPath),
              let data = fm.contents(atPath: settingsPath),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = settings["hooks"] as? [String: Any] else { return false }
        for (_, value) in hooks {
            guard let rules = value as? [[String: Any]] else { continue }
            for rule in rules {
                guard let hs = rule["hooks"] as? [[String: Any]] else { continue }
                for h in hs {
                    if (h["command"] as? String)?.contains(hookMarker) == true {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Installs HTTP curl-based hooks in settings.json.
    ///
    /// Steps:
    /// 1. Create ipcDir with 0o700 permissions.
    /// 2. Load existing settings.json (or start with empty dict).
    /// 3. For each of the 4 async hook events + 2 blocking events:
    ///    remove old CC-Beeper entries (both Python cc-beeper-hook.py and HTTP
    ///    cc-beeper/port), then append a fresh HTTP curl entry.
    /// 4. Write settings back preserving formatting (per spec section 9 item 10).
    /// 5. Clean up old Python hook files if they exist.
    static func install() throws {
        let fm = FileManager.default

        // 1. Create IPC directory
        try fm.createDirectory(atPath: ipcDir, withIntermediateDirectories: true)
        try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: ipcDir)

        // 2. Load existing settings.json or start fresh
        var settings: [String: Any] = [:]
        if let data = fm.contents(atPath: settingsPath),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = parsed
        }

        // 3. Update hook entries for 4 async events + 2 blocking events
        var hooks = settings["hooks"] as? [String: Any] ?? [:]

        // Async hook event configurations: (event name, timeout in seconds, statusMessage or nil)
        let asyncConfigs: [(String, Int, String?)] = [
            ("UserPromptSubmit", 5, nil),  // Fires when user submits prompt — prevents Stewing bug (AUDIT-03)
            ("PreToolUse",  5, "CC-Beeper monitoring\u{2026}"),  // \u2026 = ellipsis
            ("PostToolUse", 5, nil),
            ("Stop",        5, nil),
            ("StopFailure", 5, nil),
        ]

        // Blocking hook configurations (per D-01, D-02, RESEARCH.md Pitfall 5).
        // Notification is blocking because modern Claude Code routes permission_prompt
        // via Notification with notification_type: "permission_prompt". CC-Beeper
        // responds immediately with empty 200 for non-permission Notifications,
        // so there is no performance penalty for normal notifications.
        // PermissionRequest is kept as a blocking safety net for older Claude Code.
        let blockingConfigs: [(String, Int, String?)] = [
            ("Notification",       60, nil),
            ("PermissionRequest",  60, nil),
        ]

        // Events that had Python hooks but are no longer needed — clean up only
        let removedEvents = ["SessionStart", "SessionEnd", "PostToolUseFailure"]

        // Clean up removed events (remove CC-Beeper entries, keep user entries)
        for event in removedEvents {
            guard var existing = hooks[event] as? [[String: Any]] else { continue }
            existing = existing.filter { rule in
                guard let hs = rule["hooks"] as? [[String: Any]] else { return true }
                return !hs.contains { cmd in
                    let command = cmd["command"] as? String ?? ""
                    return command.contains("cc-beeper-hook.py") || command.contains(hookMarker)
                }
            }
            if existing.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = existing
            }
        }

        // Install async monitoring hooks
        for (event, timeout, statusMessage) in asyncConfigs {
            var existing = hooks[event] as? [[String: Any]] ?? []

            // Remove any previous CC-Beeper entries (Python or HTTP)
            existing = existing.filter { rule in
                guard let hs = rule["hooks"] as? [[String: Any]] else { return true }
                return !hs.contains { cmd in
                    let command = cmd["command"] as? String ?? ""
                    return command.contains("cc-beeper-hook.py") || command.contains(hookMarker)
                }
            }

            // Build new async hook entry
            var hookEntry: [String: Any] = [
                "type": "command",
                "command": asyncCommand,
                "async": true,
                "timeout": timeout,
            ]
            if let msg = statusMessage {
                hookEntry["statusMessage"] = msg
            }
            let entry: [String: Any] = ["matcher": "", "hooks": [hookEntry]]
            existing.append(entry)
            hooks[event] = existing
        }

        // Install blocking hooks (Notification + PermissionRequest, per D-01, D-02)
        for (event, timeout, statusMessage) in blockingConfigs {
            var existing = hooks[event] as? [[String: Any]] ?? []

            // Remove any previous CC-Beeper entries (Python or HTTP)
            existing = existing.filter { rule in
                guard let hs = rule["hooks"] as? [[String: Any]] else { return true }
                return !hs.contains { cmd in
                    let command = cmd["command"] as? String ?? ""
                    return command.contains("cc-beeper-hook.py") || command.contains(hookMarker)
                }
            }

            // Build blocking hook entry — NO async, NO -o /dev/null, NO || true (per D-02)
            var hookEntry: [String: Any] = [
                "type": "command",
                "command": blockingCommand,
                "timeout": timeout,
            ]
            if let msg = statusMessage {
                hookEntry["statusMessage"] = msg
            }
            let entry: [String: Any] = ["matcher": "", "hooks": [hookEntry]]
            existing.append(entry)
            hooks[event] = existing
        }

        settings["hooks"] = hooks

        // 4. Write settings.json atomically (per spec section 9 item 10: don't reformat)
        // Note: .sortedKeys intentionally removed — it caused full-file key reordering (D-03)
        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted]
        )
        let tmpPath = settingsPath + ".tmp"
        try data.write(to: URL(fileURLWithPath: tmpPath))
        // Atomic rename
        if fm.fileExists(atPath: settingsPath) {
            _ = try fm.replaceItemAt(
                URL(fileURLWithPath: settingsPath),
                withItemAt: URL(fileURLWithPath: tmpPath)
            )
        } else {
            try fm.moveItem(atPath: tmpPath, toPath: settingsPath)
        }

        // 5. Clean up old Python hook files
        let oldHookScript = hooksDir + "/cc-beeper-hook.py"
        let oldAppPathFile = hooksDir + "/cc-beeper-app-path"
        try? fm.removeItem(atPath: oldHookScript)
        try? fm.removeItem(atPath: oldAppPathFile)
        // Clean up old IPC files no longer needed
        try? fm.removeItem(atPath: ipcDir + "/events.jsonl")
        try? fm.removeItem(atPath: ipcDir + "/pending.json")
        try? fm.removeItem(atPath: ipcDir + "/response.json")
        try? fm.removeItem(atPath: ipcDir + "/last_summary.txt")
        try? fm.removeItem(atPath: ipcDir + "/sessions.json")
        try? fm.removeItem(atPath: ipcDir + "/cc-beeper.pid")
    }

    /// Removes all CC-Beeper hook entries from settings.json without touching user hooks.
    static func uninstall() throws {
        let fm = FileManager.default
        guard let data = fm.contents(atPath: settingsPath),
              var settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = settings["hooks"] as? [String: Any] else { return }

        for (event, value) in hooks {
            guard var rules = value as? [[String: Any]] else { continue }
            rules = rules.filter { rule in
                guard let hs = rule["hooks"] as? [[String: Any]] else { return true }
                return !hs.contains { cmd in
                    let command = cmd["command"] as? String ?? ""
                    return command.contains("cc-beeper-hook.py") || command.contains(hookMarker)
                }
            }
            if rules.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = rules
            }
        }
        settings["hooks"] = hooks

        // Note: .sortedKeys intentionally removed — it caused full-file key reordering (D-03)
        let writeData = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted]
        )
        // Atomic write via tmp + rename (same pattern as install())
        let tmpPath = settingsPath + ".tmp"
        try writeData.write(to: URL(fileURLWithPath: tmpPath))
        if fm.fileExists(atPath: settingsPath) {
            _ = try fm.replaceItemAt(
                URL(fileURLWithPath: settingsPath),
                withItemAt: URL(fileURLWithPath: tmpPath)
            )
        } else {
            try fm.moveItem(atPath: tmpPath, toPath: settingsPath)
        }
    }

    enum InstallError: LocalizedError {
        case settingsWriteFailed

        var errorDescription: String? {
            switch self {
            case .settingsWriteFailed:
                return "Failed to write settings.json."
            }
        }
    }
}
