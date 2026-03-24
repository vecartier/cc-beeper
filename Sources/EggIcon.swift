import AppKit

// MARK: - Egg-shaped menu bar icon

enum EggIconState {
    case normal
    case attention   // needsYou — orange
    case yolo        // autoAccept — purple
    case hidden      // powered off — dimmed
}

enum EggIcon {
    static func image(state: EggIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let color: NSColor = switch state {
        case .normal:    .black
        case .attention: .systemOrange
        case .yolo:      .systemPurple
        case .hidden:    .gray
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
