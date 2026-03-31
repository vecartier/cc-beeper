import SwiftUI
import AppKit

struct CompactView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    private let shellW: CGFloat = 220
    private let shellH: CGFloat = 113

    // LCD screen -- proportional from large shell (286x45 in 360x160)
    private let lcdW: CGFloat = 175
    private let lcdH: CGFloat = 45

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Small shell background
            Image(nsImage: loadShellImage(themeManager.smallShellImageName))
                .resizable()
                .interpolation(.high)
                .frame(width: shellW, height: shellH)

            // LCD screen -- compact mode (icon-only badge)
            ScreenView(compact: true)
                .frame(width: lcdW, height: lcdH)
                .clipped()
                .offset(x: 26, y: 31)
                .allowsHitTesting(false)
        }
        .frame(width: shellW, height: shellH)
        .padding(40)
        .background(Color.clear)
        .contextMenu {
            Button("Quit CC-Beeper") { NSApplication.shared.terminate(nil) }
        }
    }

    private func loadShellImage(_ name: String) -> NSImage {
        if let path = Bundle.main.resourcePath,
           let img = NSImage(contentsOfFile: path + "/" + name) { return img }
        return NSImage()
    }
}

#Preview {
    CompactView()
        .environmentObject(ClaudeMonitor())
        .environmentObject(ThemeManager())
}
