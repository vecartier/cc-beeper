import AppKit

// MARK: - Beeper/pager-shaped menu bar icon

enum BeeperIconState {
    case normal
    case attention   // needsYou — orange
    case yolo        // autoAccept — purple
    case hidden      // powered off — dimmed
}

enum BeeperIcon {
    static func image(state: BeeperIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let color: NSColor = .black

        let img = NSImage(size: size, flipped: true) { _ in
            // Body: wider horizontal pager rectangle (no antenna)
            let bodyRect = NSRect(x: 0, y: 2, width: 18, height: 14)
            let body = NSBezierPath(roundedRect: bodyRect, xRadius: 2.5, yRadius: 2.5)
            color.setFill()
            body.fill()

            // Screen cutout: punch through with clear
            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            let screenRect = NSRect(x: 2, y: 3.5, width: 14, height: 7)
            let screen = NSBezierPath(roundedRect: screenRect, xRadius: 1, yRadius: 1)
            screen.fill()

            // Robot face inside screen (drawn in body color on clear screen)
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            color.setFill()
            // Eyes: two small squares
            NSRect(x: 5.5, y: 5, width: 1.5, height: 1.5).fill()
            NSRect(x: 11, y: 5, width: 1.5, height: 1.5).fill()
            // Mouth: wider rectangle
            NSRect(x: 6.5, y: 7.5, width: 5, height: 1).fill()

            // 4 button dots along the bottom (punched out)
            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            for dx: CGFloat in [3, 6.5, 10, 13.5] {
                NSBezierPath(ovalIn: NSRect(x: dx, y: 12.5, width: 2, height: 2)).fill()
            }

            return true
        }
        img.isTemplate = true
        return img
    }
}
