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
            Group {
                if monitor.widgetSize == .compact {
                    CompactView()
                        .environmentObject(monitor)
                        .environmentObject(themeManager)
                        .background(WindowConfigurator())
                } else {
                    ContentView()
                        .environmentObject(monitor)
                        .environmentObject(themeManager)
                        .background(WindowConfigurator())
                }
            }
            .onAppear {
                if !hasCompletedOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Self.hideMainWindow()
                        openWindow(id: "onboarding")
                    }
                } else if monitor.widgetSize == .menuOnly {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Self.hideMainWindow()
                    }
                } else if monitor.widgetSize == .compact {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Self.resizeMainWindow(to: NSSize(width: 300, height: 193))
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

            // Sleep / Wake
            Button(monitor.isActive ? "Sleep" : "Wake") {
                monitor.isActive.toggle()
                if !monitor.isActive {
                    Self.hideMainWindow()
                } else if monitor.widgetSize == .menuOnly {
                    // Menu mode: don't show window
                } else {
                    Self.showMainWindow()
                    let windowSize = monitor.widgetSize == .compact
                        ? NSSize(width: 300, height: 193)
                        : NSSize(width: 440, height: 240)
                    Self.resizeMainWindow(to: windowSize)
                }
            }

            // Permission mode
            Menu("Permission \u{2014} \(monitor.currentPreset.label)") {
                ForEach(PermissionPreset.allCases, id: \.self) { preset in
                    Button {
                        monitor.currentPreset = preset
                    } label: {
                        HStack {
                            if monitor.currentPreset == preset {
                                Image(systemName: "checkmark")
                            }
                            Text("\(preset.label) \u{2014} \(preset.menuDescription)")
                        }
                    }
                    .disabled(monitor.isSettingsMalformed)
                }
                if monitor.isSettingsMalformed {
                    Divider()
                    Text("settings.json is malformed")
                }
            }

            // Widget size / visibility
            Menu("Size \u{2014} \(monitor.widgetSize.label)") {
                ForEach(WidgetSize.allCases, id: \.self) { size in
                    Button {
                        monitor.widgetSize = size
                        switch size {
                        case .large:
                            Self.showMainWindow()
                            Self.resizeMainWindow(to: NSSize(width: 440, height: 240))
                        case .compact:
                            Self.showMainWindow()
                            Self.resizeMainWindow(to: NSSize(width: 300, height: 193))
                        case .menuOnly:
                            Self.hideMainWindow()
                        }
                    } label: {
                        HStack {
                            if monitor.widgetSize == size {
                                Image(systemName: "checkmark")
                            }
                            Text("\(size.label) \u{2014} \(size.menuDescription)")
                        }
                    }
                }
            }

            Divider()

            // Keyboard shortcuts
            Menu("Keyboard Shortcuts") {
                Button("⌥ \(monitor.hotkeyAccept)  Accept Permission") {}
                Button("⌥ \(monitor.hotkeyDeny)  Deny Permission") {}
                Button("⌥ \(monitor.hotkeyVoice)  Voice Record") {}
                Button("⌥ \(monitor.hotkeyTerminal)  Go to Terminal") {}
                Button("⌥ \(monitor.hotkeyMute)  Read Over / Stop") {}
            }

            // Settings
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

    static func resizeMainWindow(to size: NSSize) {
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            var frame = window.frame
            // Anchor top-left: adjust y so the top edge stays put
            frame.origin.y += frame.height - size.height
            frame.size = size
            window.setFrame(frame, display: true, animate: true)
            constrainToScreen(window)
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
