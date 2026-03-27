import SwiftUI
import AppKit
import ApplicationServices

@main
struct CCBeeperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var monitor = ClaudeMonitor()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.openWindow) private var openWindow
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        Window("CC-Beeper", id: "main") {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(themeManager)
                .background(WindowConfigurator())
                .onAppear {
                    if !hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            Self.hideMainWindow()
                            openWindow(id: "onboarding")
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)

        Window("Setup CC-Beeper", id: "onboarding") {
            OnboardingView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 600, height: 520)

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(monitor)
                .environmentObject(themeManager)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 580, height: 420)

        MenuBarExtra {
            // Status
            Text("Sessions: \(monitor.sessionCount)")
            Text(monitor.state.label)
                .foregroundColor(.secondary)

            Divider()

            Toggle("YOLO Mode", isOn: $monitor.autoAccept)

            Divider()

            Button(Self.isMainWindowVisible() ? "Hide Widget" : "Show Widget") {
                Self.toggleMainWindow()
            }

            Button(monitor.isActive ? "Sleep" : "Awake") {
                monitor.isActive.toggle()
                if !monitor.isActive {
                    Self.hideMainWindow()
                } else {
                    Self.showMainWindow()
                }
            }

            Divider()

            Menu("Keyboard Shortcuts") {
                Button("⌥ \(keyCodeToString(monitor.hotkeyAccept))  Accept Permission") {}
                Button("⌥ \(keyCodeToString(monitor.hotkeyDeny))  Deny Permission") {}
                Button("⌥ \(keyCodeToString(monitor.hotkeyVoice))  Voice Record") {}
                Button("⌥ \(keyCodeToString(monitor.hotkeyTerminal))  Go to Terminal") {}
                Button("⌥ \(keyCodeToString(monitor.hotkeyMute))  VoiceOver / Stop") {}
            }

            Button("Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }

            Divider()

            Button("Quit CC-Beeper") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: BeeperIcon.image(state: monitor.menuBarIconState))
        }
        .menuBarExtraStyle(.menu)
    }

    static func isMainWindowVisible() -> Bool {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            return window.isVisible
        }
        return false
    }

    static func toggleMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.isVisible ? window.orderOut(nil) : window.makeKeyAndOrderFront(nil)
            return
        }
    }

    static func showMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
            return
        }
    }

    static func hideMainWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.orderOut(nil)
            return
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let pidFile = NSHomeDirectory() + "/.claude/cc-beeper/cc-beeper.pid"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let existing = Self.readPID(), Self.isProcessAlive(existing) {
            NSApp.terminate(nil)
            return
        }
        Self.writePID()

        AppMover.moveToApplicationsIfNeeded()

        let hasOnboarded = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if hasOnboarded && !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Self.removePID()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            CCBeeperApp.showMainWindow()
        }
        return false
    }

    // MARK: - PID Management

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
        if let stored = readPID(), stored == ProcessInfo.processInfo.processIdentifier {
            try? FileManager.default.removeItem(atPath: pidFile)
        }
    }

    private static func isProcessAlive(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }
}
