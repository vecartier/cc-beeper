import AppKit
import Foundation

/// Unified focus routing — consolidates terminal/IDE activation and tab targeting (Phase 44).
///
/// Priority chain:
/// 1. Tab-level focus via AppleScript (iTerm2, Terminal.app) or AX (Ghostty)
/// 2. App-level activation for IDEs and unsupported terminals
/// 3. Graceful fallback: never throws, logs failures
enum FocusService {

    // MARK: - Public API

    /// Focus the app running the active Claude session. Tries tab-level first, falls back to app-level.
    /// Called by Option-T hotkey and goToConversation().
    static func focusClaudeSession() {
        // Find a running app that matches any focusable bundle ID
        guard let (app, category) = findFocusableApp() else {
            log("no focusable app found")
            return
        }

        let bid = app.bundleIdentifier ?? ""

        switch category {
        case .iterm2:
            focusITerm2Tab(app: app) // TAB-01
        case .terminalApp:
            focusTerminalAppTab(app: app) // TAB-02
        case .ghostty:
            // TAB-03: Ghostty tab focus via AX is undocumented — fall back to app-level
            app.activate()
            log("focused Ghostty (app-level, tab AX undocumented): \(bid)")
        case .terminal, .ide:
            app.activate()
            log("focused \(category) (app-level): \(bid)")
        }
    }

    /// Focus a terminal for voice injection. Returns true if a terminal/IDE is frontmost after focusing.
    /// Used by VoiceService before injecting text.
    static func focusTerminalForInjection() -> Bool {
        guard let (app, category) = findFocusableApp() else {
            log("no terminal/IDE found for injection")
            return false
        }

        let bid = app.bundleIdentifier ?? ""

        // If already frontmost, no wait needed
        if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier {
            return true
        }

        // Wait for activation via notification (FRAG-01)
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
        let result = semaphore.wait(timeout: .now() + 0.5)
        NSWorkspace.shared.notificationCenter.removeObserver(observer)

        if result == .timedOut {
            log("focus timed out for injection — proceeding: \(bid)")
        }

        // For IDEs, try to focus the integrated terminal panel (IDE-04)
        if category == .ide {
            sendTerminalPanelShortcut(bid: bid)
        }

        return isFocusableAppFrontmost()
    }

    /// Check if the frontmost app is a known terminal or IDE (injection safety).
    static func isFocusableAppFrontmost() -> Bool {
        let bid = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        return AppConstants.allFocusableBundleIDs.contains(bid)
    }

    // MARK: - App Discovery

    private enum AppCategory {
        case iterm2, terminalApp, ghostty, terminal, ide
    }

    /// Find the first running app that matches our focusable bundle IDs.
    /// Prefers terminals over IDEs (most Claude sessions run in standalone terminals).
    private static func findFocusableApp() -> (NSRunningApplication, AppCategory)? {
        let running = NSWorkspace.shared.runningApplications

        // Check terminals first (higher priority)
        for app in running {
            guard let bid = app.bundleIdentifier else { continue }
            if bid == "com.googlecode.iterm2" { return (app, .iterm2) }
            if bid == "com.apple.Terminal" { return (app, .terminalApp) }
            if bid == "com.mitchellh.ghostty" { return (app, .ghostty) }
            if AppConstants.terminalBundleIDs.contains(bid) { return (app, .terminal) }
        }
        // Then IDEs
        for app in running {
            guard let bid = app.bundleIdentifier else { continue }
            if AppConstants.ideBundleIDs.contains(bid) || AppConstants.jetbrainsBundleIDs.contains(bid) {
                return (app, .ide)
            }
        }
        return nil
    }

    // MARK: - Tab-Level Focus

    /// Focus exact iTerm2 tab via AppleScript (TAB-01).
    private static func focusITerm2Tab(app: NSRunningApplication) {
        // AppleScript: tell iTerm2 to select the tab/session matching the Claude process
        let script = """
        tell application "iTerm2"
            activate
            tell current window
                repeat with aTab in tabs
                    repeat with aSession in sessions of aTab
                        if tty of aSession contains "claude" then
                            select aTab
                            select aSession
                            return
                        end if
                    end repeat
                end repeat
            end tell
        end tell
        """
        if !runAppleScript(script) {
            // TAB-04: graceful fallback
            app.activate()
            log("iTerm2 tab targeting failed — fell back to app-level")
        } else {
            log("focused iTerm2 tab via AppleScript")
        }
    }

    /// Focus exact Terminal.app tab via AppleScript (TAB-02).
    private static func focusTerminalAppTab(app: NSRunningApplication) {
        let script = """
        tell application "Terminal"
            activate
            set frontWindow to front window
            repeat with i from 1 to count of tabs of frontWindow
                set currentTab to tab i of frontWindow
                if processes of currentTab contains "claude" then
                    set selected tab of frontWindow to currentTab
                    return
                end if
            end repeat
        end tell
        """
        if !runAppleScript(script) {
            // TAB-04: graceful fallback
            app.activate()
            log("Terminal.app tab targeting failed — fell back to app-level")
        } else {
            log("focused Terminal.app tab via AppleScript")
        }
    }

    // MARK: - IDE Terminal Panel (IDE-04)

    /// Send keyboard shortcut to toggle/focus the integrated terminal panel.
    private static func sendTerminalPanelShortcut(bid: String) {
        // Common shortcuts: Ctrl+` for VS Code/Cursor/Zed, Alt+F12 for JetBrains
        let shortcut: (key: UInt16, flags: CGEventFlags)
        if AppConstants.jetbrainsBundleIDs.contains(bid) {
            shortcut = (0x6F, .maskAlternate) // Alt+F12
        } else {
            shortcut = (0x32, .maskControl) // Ctrl+` (backtick)
        }

        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: shortcut.key, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: shortcut.key, keyDown: false) else {
            log("IDE terminal shortcut CGEvent creation failed (IDE-05)")
            return
        }
        down.flags = shortcut.flags
        up.flags = shortcut.flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        usleep(50_000) // brief wait for panel to open
        log("sent terminal panel shortcut to IDE: \(bid)")
    }

    // MARK: - Helpers

    private static func runAppleScript(_ source: String) -> Bool {
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
    }

    private static func log(_ msg: String) {
        let line = "[\(Date())] FocusService: \(msg)\n"
        let logPath = NSHomeDirectory() + "/.claude/cc-beeper/focus.log"
        if let fh = FileHandle(forWritingAtPath: logPath) {
            fh.seekToEndOfFile()
            fh.write(line.data(using: .utf8)!)
            fh.closeFile()
        } else {
            FileManager.default.createFile(
                atPath: logPath, contents: line.data(using: .utf8),
                attributes: [.posixPermissions: 0o600]
            )
        }
    }
}
