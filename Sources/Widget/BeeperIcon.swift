import AppKit

// MARK: - Beeper/pager-shaped menu bar icon

enum BeeperIconState {
    case normal
    case attention   // needsYou — orange
    case yolo        // autoAccept — purple
    case hidden      // powered off — dimmed
    case recording   // voice recording active
    case speaking    // TTS playing
}

enum BeeperIcon {
    static func image(state: BeeperIconState) -> NSImage {
        switch state {
        case .recording:
            return recordingIcon()
        case .speaking:
            return speakingIcon()
        default:
            return beeperIcon()
        }
    }

    // MARK: - Beeper (default)

    private static func beeperIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let color: NSColor = .black

        let img = NSImage(size: size, flipped: true) { _ in
            let bodyRect = NSRect(x: 0, y: 2, width: 18, height: 14)
            let body = NSBezierPath(roundedRect: bodyRect, xRadius: 2.5, yRadius: 2.5)
            color.setFill()
            body.fill()

            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            let screenRect = NSRect(x: 2, y: 3.5, width: 14, height: 7)
            NSBezierPath(roundedRect: screenRect, xRadius: 1, yRadius: 1).fill()

            NSGraphicsContext.current?.compositingOperation = .sourceOver
            color.setFill()
            NSRect(x: 5.5, y: 5, width: 1.5, height: 1.5).fill()
            NSRect(x: 11, y: 5, width: 1.5, height: 1.5).fill()
            NSRect(x: 6.5, y: 7.5, width: 5, height: 1).fill()

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

    // MARK: - Recording (circle with stop square inside)

    private static func recordingIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: true) { _ in
            NSColor.black.setFill()
            // Outer circle
            NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: 16, height: 16)).fill()
            // Stop square punched out
            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            let sq = NSRect(x: 5.5, y: 5.5, width: 7, height: 7)
            NSBezierPath(roundedRect: sq, xRadius: 1.5, yRadius: 1.5).fill()
            return true
        }
        img.isTemplate = true
        return img
    }

    // MARK: - Speaking (speech bubble)

    private static func speakingIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: true) { _ in
            NSColor.black.setFill()
            // Speech bubble body
            let bubbleRect = NSRect(x: 1, y: 1, width: 16, height: 12)
            NSBezierPath(roundedRect: bubbleRect, xRadius: 3, yRadius: 3).fill()
            // Tail triangle
            let tail = NSBezierPath()
            tail.move(to: NSPoint(x: 4, y: 13))
            tail.line(to: NSPoint(x: 2, y: 17))
            tail.line(to: NSPoint(x: 8, y: 13))
            tail.close()
            tail.fill()

            // Three dots inside bubble (speaking indicator)
            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            NSBezierPath(ovalIn: NSRect(x: 4.5, y: 5.5, width: 2, height: 2)).fill()
            NSBezierPath(ovalIn: NSRect(x: 8, y: 5.5, width: 2, height: 2)).fill()
            NSBezierPath(ovalIn: NSRect(x: 11.5, y: 5.5, width: 2, height: 2)).fill()
            return true
        }
        img.isTemplate = true
        return img
    }
}
