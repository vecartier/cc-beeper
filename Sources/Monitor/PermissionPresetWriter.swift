import Foundation

// MARK: - WidgetSize

/// Controls widget visibility: full beeper, screen only, or menu bar only.
enum WidgetSize: String, CaseIterable, Equatable {
    case large       // Full beeper with buttons
    case compact     // Screen only, no buttons
    case menuOnly    // No widget, menu bar only

    var label: String {
        switch self {
        case .large: return "Large"
        case .compact: return "Compact"
        case .menuOnly: return "Menu only"
        }
    }

    var menuDescription: String {
        switch self {
        case .large: return "full beeper with buttons"
        case .compact: return "screen only, hotkeys to interact"
        case .menuOnly: return "menu bar icon only"
        }
    }
}

// MARK: - PermissionPreset

/// The 4 permission presets available in CC-Beeper.
/// YOLO sets `permissions.defaultMode: "bypassPermissions"` in settings.json.
/// Other presets auto-approve tools via PermissionRequest hook responses.
enum PermissionPreset: String, CaseIterable, Equatable {
    case cautious   // ask before every action
    case trusted    // auto file ops (Read/Glob/Grep/Write/Edit/NotebookEdit), ask for bash
    case relaxed    // auto reads (Read/Glob/Grep), ask for writes
    case yolo       // permissions.defaultMode: "bypassPermissions"

    /// The value to write to `permissions.defaultMode` in settings.json.
    /// Claude Code recognises: "default", "plan", "acceptEdits", "bypassPermissions".
    var defaultModeValue: String? {
        switch self {
        case .cautious, .relaxed, .trusted: return nil   // remove → Claude Code uses "default"
        case .yolo: return "bypassPermissions"
        }
    }

    /// Tools that CC-Beeper auto-approves via its PermissionRequest hook response.
    /// These are NOT written to settings.json — they're checked at hook time only.
    var allowedTools: [String]? {
        switch self {
        case .cautious: return nil
        case .relaxed: return ["Read", "Glob", "Grep"]
        case .trusted: return ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"]
        case .yolo: return nil  // YOLO bypasses everything via defaultMode
        }
    }

    /// Human-readable label for the menu and UI.
    var label: String {
        switch self {
        case .cautious: return "Strict"
        case .trusted: return "Cautious"
        case .relaxed: return "Relaxed"
        case .yolo: return "YOLO"
        }
    }

    /// Short description shown alongside the label in the menu.
    var menuDescription: String {
        switch self {
        case .cautious: return "ask before every action"
        case .relaxed: return "auto reads, ask for writes"
        case .trusted: return "auto file ops, ask for bash"
        case .yolo: return "auto-approve everything"
        }
    }

    /// SF Symbol for the LCD badge.
    var badgeIcon: String {
        switch self {
        case .cautious: return "shield.fill"
        case .trusted: return "eye.fill"
        case .relaxed: return "hand.thumbsup.fill"
        case .yolo: return "flame.fill"
        }
    }

    /// Short text for the LCD badge.
    var badgeLabel: String {
        label.uppercased()
    }
}

// MARK: - PermissionPresetWriter

/// Reads and writes permission presets to ~/.claude/settings.json atomically.
///
/// Write strategy: read existing JSON, modify `permissions.defaultMode`,
/// write to a .tmp file, then atomically rename — preserving all other fields intact.
struct PermissionPresetWriter {

    static let settingsPath = NSHomeDirectory() + "/.claude/settings.json"

    // MARK: Read

    /// Reads the current preset.
    ///
    /// Primary source: UserDefaults (`ccBeeperPreset`).
    /// Fallback: infer from `permissions.defaultMode` in settings.json.
    static func readCurrentPreset() -> PermissionPreset {
        // UserDefaults is the source of truth (written by applyPreset)
        if let raw = UserDefaults.standard.string(forKey: "ccBeeperPreset"),
           let preset = PermissionPreset(rawValue: raw) {
            return preset
        }

        // Fallback: infer from settings.json (first launch or UserDefaults cleared)
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsPath),
              let data = fm.contents(atPath: settingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .cautious
        }

        let perms = json["permissions"] as? [String: Any] ?? [:]
        if let mode = perms["defaultMode"] as? String, mode == "bypassPermissions" {
            return .yolo
        }

        // Legacy field migration
        if let mode = json["permission_mode"] as? String, mode == "bypass" {
            return .yolo
        }

        return .cautious
    }

    // MARK: Malformed Detection

    /// One-time migration: remove legacy `permission_mode` and `allowedTools` root fields,
    /// and ensure `permissions.defaultMode` matches the current preset.
    static func migrateLegacyFields() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsPath),
              let data = fm.contents(atPath: settingsPath),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        let hasLegacy = settings["permission_mode"] != nil || settings["allowedTools"] != nil
        guard hasLegacy else { return }

        // Apply current preset to write correct fields and remove legacy ones
        let preset = readCurrentPreset()
        try? applyPreset(preset)
    }

    /// Returns true if settings.json exists but cannot be parsed as valid JSON.
    static func isSettingsMalformed() -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsPath),
              let data = fm.contents(atPath: settingsPath) else {
            return false  // Missing file is not malformed — it will be created on write
        }
        return (try? JSONSerialization.jsonObject(with: data)) == nil
    }

    // MARK: Write

    /// Applies a preset to settings.json.
    ///
    /// Writes `permissions.defaultMode` (the correct Claude Code field) and persists
    /// the preset name to UserDefaults. Cleans up legacy `permission_mode` and
    /// `allowedTools` root fields if present.
    ///
    /// - Parameter preset: The preset to apply.
    /// - Throws: If the file cannot be written.
    static func applyPreset(_ preset: PermissionPreset) throws {
        let fm = FileManager.default

        // Persist preset to UserDefaults (source of truth for CC-Beeper)
        UserDefaults.standard.set(preset.rawValue, forKey: "ccBeeperPreset")

        // Read existing settings or start fresh
        var settings: [String: Any] = [:]
        if fm.fileExists(atPath: settingsPath),
           let data = fm.contents(atPath: settingsPath),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = parsed
        }

        // Get or create the permissions object
        var perms = settings["permissions"] as? [String: Any] ?? [:]

        // Set permissions.defaultMode
        if let mode = preset.defaultModeValue {
            perms["defaultMode"] = mode
        } else {
            perms.removeValue(forKey: "defaultMode")
        }

        settings["permissions"] = perms

        // Clean up legacy CC-Beeper fields that Claude Code doesn't recognise
        settings.removeValue(forKey: "permission_mode")
        settings.removeValue(forKey: "allowedTools")

        // Serialize — .sortedKeys is INTENTIONALLY OMITTED to minimize reformatting
        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted]
        )

        // Atomic write via tmp + rename
        let tmpPath = settingsPath + ".tmp"
        try data.write(to: URL(fileURLWithPath: tmpPath))
        if fm.fileExists(atPath: settingsPath) {
            _ = try fm.replaceItemAt(
                URL(fileURLWithPath: settingsPath),
                withItemAt: URL(fileURLWithPath: tmpPath)
            )
        } else {
            try fm.moveItem(atPath: tmpPath, toPath: settingsPath)
        }
    }
}
