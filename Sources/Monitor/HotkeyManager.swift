import Foundation
import HotKey
import Carbon.HIToolbox

// MARK: - Hotkey Manager (ARCH-04)
// Global hotkey registration and character-to-keyCode resolution.

extension ClaudeMonitor {

    func setupGlobalHotkeys() {
        carbonHotKeys.removeAll()

        let debugPath = Self.ipcDir + "/hotkeys-debug.txt"
        var debugLog = "setupGlobalHotkeys called at \(Date())\n"
        debugLog += "accept=\(hotkeyAccept) deny=\(hotkeyDeny) voice=\(hotkeyVoice) terminal=\(hotkeyTerminal) mute=\(hotkeyMute)\n"

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
    func migrateHotkeyDefaults() {
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
}
