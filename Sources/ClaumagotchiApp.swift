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
            Text("Status: \(monitor.autoAccept ? "YOLO MODE" : monitor.state.label)")
            if let pending = monitor.pendingPermission {
                Divider()
                Text("\(pending.tool): \(pending.summary)")
                    .font(.caption)
                Button("Allow") { monitor.respondToPermission(allow: true) }
                    .keyboardShortcut("a")
                Button("Deny") { monitor.respondToPermission(allow: false) }
                    .keyboardShortcut("d")
            }
            if monitor.state.canGoToConvo {
                Divider()
                Button("Go to Conversation") { monitor.goToConversation() }
                    .keyboardShortcut("g")
            }
            Divider()
            Button(monitor.autoAccept ? "Disable YOLO Mode" : "Enable YOLO Mode") {
                monitor.autoAccept.toggle()
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            Button(monitor.soundEnabled ? "Disable Sounds" : "Enable Sounds") {
                monitor.soundEnabled.toggle()
            }
            .keyboardShortcut("s")
            Button(monitor.notificationsEnabled ? "Disable Notifications" : "Enable Notifications") {
                monitor.notificationsEnabled.toggle()
            }
            .keyboardShortcut("n")
            Divider()
            Menu("Theme") {
                Picker("Color", selection: $themeManager.currentThemeId) {
                    ForEach(ThemeManager.themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                Divider()
                Toggle("Dark Mode", isOn: $themeManager.darkMode)
            }
            Divider()
            if !AXIsProcessTrusted() {
                Button("Enable Global Hotkeys...") {
                    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                    _ = AXIsProcessTrustedWithOptions(opts)
                }
            }
            Button("Show / Hide") { Self.toggleMainWindow() }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            Button("Quit Claumagotchi") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: EggIcon.image(state: monitor.yoloIconState))
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
}

// MARK: - Egg-shaped menu bar icon

enum EggIconState {
    case normal
    case attention   // needsYou — orange
    case yolo        // autoAccept — purple
}

enum EggIcon {
    static func image(state: EggIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let color: NSColor = switch state {
        case .normal:    .black
        case .attention: .systemOrange
        case .yolo:      .systemPurple
        }

        let img = NSImage(size: size, flipped: true) { _ in
            let eggRect = NSRect(x: 2, y: 1, width: 14, height: 16)
            let egg = NSBezierPath(ovalIn: eggRect)
            color.setFill()
            egg.fill()

            let screen = NSRect(x: 5, y: 4, width: 8, height: 6)
            let screenPath = NSBezierPath(roundedRect: screen, xRadius: 1, yRadius: 1)
            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            screenPath.fill()

            NSGraphicsContext.current?.compositingOperation = .sourceOver
            color.setFill()
            NSRect(x: 7, y: 6, width: 1.5, height: 1.5).fill()
            NSRect(x: 10, y: 6, width: 1.5, height: 1.5).fill()
            NSRect(x: 8, y: 8, width: 3, height: 1).fill()

            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            for dx: CGFloat in [5.5, 8.5, 11.5] {
                NSBezierPath(ovalIn: NSRect(x: dx, y: 12, width: 1.5, height: 1.5)).fill()
            }
            return true
        }
        img.isTemplate = (state == .normal)
        return img
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

// MARK: - Window Configurator

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            // Remove all title bar buttons
            window.styleMask.remove(.titled)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            // Constrain to screen bounds
            constrainToScreen(window)
            NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: window, queue: .main
            ) { _ in constrainToScreen(window) }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private func constrainToScreen(_ window: NSWindow) {
    guard let screen = window.screen ?? NSScreen.main else { return }
    let visible = screen.visibleFrame
    var frame = window.frame

    if frame.minX < visible.minX { frame.origin.x = visible.minX }
    if frame.minY < visible.minY { frame.origin.y = visible.minY }
    if frame.maxX > visible.maxX { frame.origin.x = visible.maxX - frame.width }
    if frame.maxY > visible.maxY { frame.origin.y = visible.maxY - frame.height }

    if frame != window.frame {
        window.setFrame(frame, display: false)
    }
}
