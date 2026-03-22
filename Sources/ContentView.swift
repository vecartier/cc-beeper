import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    // Shell image: egg only, no padding. 200×242 (from 800×970 @ 4x)
    private let canvasW: CGFloat = 200
    private let canvasH: CGFloat = 242

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Shell background image — themed
            Image(nsImage: loadShellImage(themeManager.shellImageName))
                .resizable()
                .frame(width: canvasW, height: canvasH)

            // LCD screen content — centered horizontally, top=54, 120×88 (from Figma)
            ScreenView()
                .frame(width: 116, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .position(x: canvasW / 2, y: 99)
                .allowsHitTesting(false)

            // Buttons — positioned at Figma centers
            // Arrow/Terminal (top-left) — further out
            LeftActionButton(
                symbol: "arrow.up.forward",
                active: true
            ) { monitor.goToConversation() }
            .position(x: 46, y: 172)
            .accessibilityLabel("Go to terminal")

            // Record/Mic (bottom-left) — closer to center
            LeftActionButton(
                symbol: monitor.isRecording ? "stop.fill" : "mic.fill",
                active: true,
                pulse: monitor.isRecording,
                iconColor: monitor.isRecording ? Color(hex: "FF2929") : nil
            ) { monitor.voiceService.toggle() }
            .position(x: 68, y: 204)
            .accessibilityLabel(monitor.isRecording ? "Stop recording" : "Speak")

            // Check/Accept (top-right) — further out
            ActionButton(
                symbol: "checkmark",
                active: monitor.state.needsAttention,
                pulse: monitor.state.needsAttention
            ) { monitor.respondToPermission(allow: true) }
            .position(x: 154, y: 172)
            .accessibilityLabel("Accept permission")

            // X/Deny (bottom-right) — closer to center
            ActionButton(
                symbol: "xmark",
                active: monitor.state.needsAttention
            ) { monitor.respondToPermission(allow: false) }
            .position(x: 132, y: 204)
            .accessibilityLabel("Deny permission")
        }
        .frame(width: canvasW, height: canvasH)
        .background(Color.clear)
        .contextMenu {
            Button("Quit Claumagotchi") { NSApplication.shared.terminate(nil) }
        }
    }


    // Load shell image by theme name — try bundle Resources, then source tree
    private func loadShellImage(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/" + name) { return img }
        if let img = NSImage(contentsOfFile: "/Users/vcartier/Desktop/Claumagotchi/Sources/shells/" + name) { return img }
        // Fallback to default
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/shell.png") { return img }
        if let img = NSImage(contentsOfFile: "/Users/vcartier/Desktop/Claumagotchi/Sources/shells/shell-orange.png") { return img }
        return NSImage()
    }
}

