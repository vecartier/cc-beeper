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
                Button("⌥ \(monitor.hotkeyAccept)  Accept Permission") {}
                Button("⌥ \(monitor.hotkeyDeny)  Deny Permission") {}
                Button("⌥ \(monitor.hotkeyVoice)  Voice Record") {}
                Button("⌥ \(monitor.hotkeyTerminal)  Go to Terminal") {}
                Button("⌥ \(monitor.hotkeyMute)  Read Over / Stop") {}
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Port-based instance detection (replaces PID check per D-11)
        if let port = HTTPHookServer.readPort() {
            if HTTPHookServer.isPortResponding(port) {
                // Another instance is running — show alert and quit
                let alert = NSAlert()
                alert.messageText = "CC-Beeper Already Running"
                alert.informativeText = "Another CC-Beeper instance is already listening on port \(port)."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Quit")
                alert.runModal()
                NSApp.terminate(nil)
                return
            } else {
                // Stale port file from a crash — clean up
                try? FileManager.default.removeItem(atPath: HTTPHookServer.portFile)
            }
        }
        // Also clean up old PID file if it exists from previous versions
        let oldPidFile = NSHomeDirectory() + "/.claude/cc-beeper/cc-beeper.pid"
        try? FileManager.default.removeItem(atPath: oldPidFile)

        AppMover.moveToApplicationsIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up port file so the next launch doesn't see a stale port.
        try? FileManager.default.removeItem(atPath: HTTPHookServer.portFile)
        // Clean up old PID file just in case.
        let oldPidFile = NSHomeDirectory() + "/.claude/cc-beeper/cc-beeper.pid"
        try? FileManager.default.removeItem(atPath: oldPidFile)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            CCBeeperApp.showMainWindow()
        }
        return false
    }
}
