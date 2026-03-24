import SwiftUI
import AppKit

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

func constrainToScreen(_ window: NSWindow) {
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
