import SwiftUI
import AppKit
import ApplicationServices

@main
struct ClaumagotchiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var monitor = ClaudeMonitor()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        Window("Claumagotchi", id: "main") {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(themeManager)
                .background(WindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)

        MenuBarExtra {
            // SECTION 1: Status
            Text("Sessions: \(monitor.sessionCount)")
            Text(monitor.autoAccept ? "YOLO MODE" : monitor.state.label)
                .foregroundColor(.secondary)

            Divider()

            // SECTION 2: Controls
            Toggle("YOLO Mode", isOn: $monitor.autoAccept)
                .keyboardShortcut("y")
            Toggle("Auto-Speak", isOn: $monitor.autoSpeak)
                .keyboardShortcut("k")
            Toggle("Sound Effects", isOn: $monitor.soundEnabled)
                .keyboardShortcut("s")
            Toggle("Notifications", isOn: $monitor.notificationsEnabled)
                .keyboardShortcut("n")
            Toggle("Vibration", isOn: $monitor.vibrationEnabled)
                .keyboardShortcut("v")

            Divider()

            // SECTION 3: App
            Menu("Theme") {
                Picker("Color", selection: $themeManager.currentThemeId) {
                    ForEach(ThemeManager.themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                Divider()
                Toggle("Dark Mode", isOn: $themeManager.darkMode)
            }

            Button("Show / Hide Widget") {
                Self.toggleMainWindow()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button(monitor.isActive ? "Power Off" : "Power On") {
                monitor.isActive.toggle()
                if !monitor.isActive {
                    Self.hideMainWindow()
                } else {
                    Self.showMainWindow()
                }
            }
            .keyboardShortcut("p")

            if !AXIsProcessTrusted() {
                Button("Enable Global Hotkeys...") {
                    let key = "AXTrustedCheckOptionPrompt" as CFString
                    let opts = [key as String: true] as CFDictionary
                    _ = AXIsProcessTrustedWithOptions(opts)
                }
            }

            Divider()

            Button("Quit Claumagotchi") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: EggIcon.image(state: monitor.menuBarIconState))
        }
        .menuBarExtraStyle(.menu)
    }

    static func toggleMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.isVisible ? window.orderOut(nil) : window.makeKeyAndOrderFront(nil)
            return
        }
    }

    /// Show the main window without toggling (used by applicationShouldHandleReopen).
    static func showMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
            return
        }
    }

    /// Hide the main window without toggling (used by Power Off).
    static func hideMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.orderOut(nil)
            return
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let pidFile = NSHomeDirectory() + "/.claude/claumagotchi/claumagotchi.pid"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Enforce single instance via PID file — works even when the app is
        // installed in multiple locations (e.g. /Applications/ AND ~/Desktop/).
        if let existing = Self.readPID(), Self.isProcessAlive(existing) {
            // Another Claumagotchi is already running — quit silently.
            NSApp.terminate(nil)
            return
        }
        Self.writePID()

        // One-time Accessibility prompt on first launch
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up PID file so the next launch doesn't see a stale PID.
        Self.removePID()
    }

    /// Prevent `open Claumagotchi.app` from creating a second window when already running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            ClaumagotchiApp.showMainWindow()
        }
        return false
    }

    // MARK: PID File Helpers

    private static func readPID() -> pid_t? {
        guard let data = FileManager.default.contents(atPath: pidFile),
              let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int32(str) else { return nil }
        return pid
    }

    private static func writePID() {
        let dir = (pidFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let pid = ProcessInfo.processInfo.processIdentifier
        try? "\(pid)\n".write(toFile: pidFile, atomically: true, encoding: .utf8)
    }

    private static func removePID() {
        // Only remove if it's our PID (avoid race with a replacement instance).
        if let stored = readPID(), stored == ProcessInfo.processInfo.processIdentifier {
            try? FileManager.default.removeItem(atPath: pidFile)
        }
    }

    private static func isProcessAlive(_ pid: pid_t) -> Bool {
        // kill(pid, 0) checks existence without sending a signal.
        kill(pid, 0) == 0
    }
}

