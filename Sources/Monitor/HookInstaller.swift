import Foundation

struct HookInstaller {
    static let hooksDir    = NSHomeDirectory() + "/.claude/hooks"
    static let ipcDir      = NSHomeDirectory() + "/.claude/cc-beeper"
    static let settingsPath = NSHomeDirectory() + "/.claude/settings.json"
    static let hookScript  = hooksDir + "/cc-beeper-hook.py"
    static let appPathFile = hooksDir + "/cc-beeper-app-path"

    /// Returns true when the hook script exists on disk AND settings.json contains
    /// at least one hook entry whose command references cc-beeper-hook.py.
    static var isInstalled: Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: hookScript),
              fm.fileExists(atPath: settingsPath) else { return false }
        guard let data = fm.contents(atPath: settingsPath),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = settings["hooks"] as? [String: Any] else { return false }
        for (_, value) in hooks {
            guard let rules = value as? [[String: Any]] else { continue }
            for rule in rules {
                guard let hs = rule["hooks"] as? [[String: Any]] else { continue }
                for h in hs {
                    if (h["command"] as? String)?.contains("cc-beeper-hook.py") == true {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Replicates setup.py entirely in Swift. Does NOT spawn a python3 subprocess.
    ///
    /// Steps:
    /// 1. Create hooksDir and ipcDir (with intermediate directories).
    /// 2. Set ipcDir permissions to 0o700.
    /// 3. Copy hook script from the app bundle to hookScript path; set permissions to 0o755.
    /// 4. Write the current app bundle path to appPathFile.
    /// 5. Load existing settings.json (or start with an empty dict).
    /// 6. For each of the 8 hook events: remove any existing cc-beeper entries,
    ///    then append a fresh entry with the correct timeout.
    /// 7. Write settings back as pretty-printed, sorted-keys JSON.
    static func install() throws {
        let fm = FileManager.default

        // 1. Create directories
        try fm.createDirectory(atPath: hooksDir, withIntermediateDirectories: true)
        try fm.createDirectory(atPath: ipcDir, withIntermediateDirectories: true)

        // 2. Secure the IPC directory
        try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: ipcDir)

        // 3. Copy hook script from app bundle resources
        guard let bundleScript = Bundle.main.path(forResource: "cc-beeper-hook", ofType: "py") else {
            throw InstallError.hookScriptNotInBundle
        }
        if fm.fileExists(atPath: hookScript) {
            try fm.removeItem(atPath: hookScript)
        }
        try fm.copyItem(atPath: bundleScript, toPath: hookScript)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hookScript)

        // 4. Write current bundle path so the hook knows where to find the app
        let appPath = Bundle.main.bundlePath
        try (appPath + "\n").write(toFile: appPathFile, atomically: true, encoding: .utf8)

        // 5. Load existing settings.json or start fresh
        var settings: [String: Any] = [:]
        if let data = fm.contents(atPath: settingsPath),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = parsed
        }

        // 6. Update hook entries for all 8 events (mirrors HOOK_CONFIGS in setup.py)
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        let cmd = "python3 \(hookScript)"
        let eventConfigs: [(String, Int)] = [
            ("PreToolUse",        5),
            ("PostToolUse",       5),
            ("PostToolUseFailure", 5),
            ("PermissionRequest", 60),
            ("Notification",      5),
            ("Stop",              5),
            ("SessionStart",      10),
            ("SessionEnd",        5),
        ]
        for (event, timeout) in eventConfigs {
            var existing = hooks[event] as? [[String: Any]] ?? []
            // Remove any previous cc-beeper entries
            existing = existing.filter { rule in
                guard let hs = rule["hooks"] as? [[String: Any]] else { return true }
                return !hs.contains { ($0["command"] as? String)?.contains("cc-beeper-hook.py") == true }
            }
            // Append fresh entry
            let hookEntry: [String: Any] = [
                "type": "command",
                "command": cmd,
                "timeout": timeout,
            ]
            let entry: [String: Any] = ["matcher": "", "hooks": [hookEntry]]
            existing.append(entry)
            hooks[event] = existing
        }
        settings["hooks"] = hooks

        // 7. Write settings.json with pretty-printed, sorted keys
        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: URL(fileURLWithPath: settingsPath))
    }

    enum InstallError: LocalizedError {
        case hookScriptNotInBundle

        var errorDescription: String? {
            switch self {
            case .hookScriptNotInBundle:
                return "The hook script (cc-beeper-hook.py) was not found in the app bundle."
            }
        }
    }
}
