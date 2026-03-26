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
        let color: NSColor = switch state {
        case .normal:    .black
        case .attention: .systemOrange
        case .yolo:      .systemPurple
        case .hidden:    .gray
        }

        let img = NSImage(size: size, flipped: true) { _ in
            // Body: horizontal pager rectangle
            let bodyRect = NSRect(x: 1, y: 4, width: 16, height: 11)
            let body = NSBezierPath(roundedRect: bodyRect, xRadius: 2.5, yRadius: 2.5)
            color.setFill()
            body.fill()

            // Antenna nub: small rect on top-right corner
            let antennaRect = NSRect(x: 13, y: 1, width: 2, height: 4)
            let antenna = NSBezierPath(roundedRect: antennaRect, xRadius: 1, yRadius: 1)
            color.setFill()
            antenna.fill()

            // Screen cutout: punch through with clear
            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            let screenRect = NSRect(x: 3, y: 6, width: 9, height: 5)
            let screen = NSBezierPath(roundedRect: screenRect, xRadius: 1, yRadius: 1)
            screen.fill()

            // Button dots: 3 small circles along right side (punched out)
            for dy: CGFloat in [6.5, 9.5, 12.5] {
                NSBezierPath(ovalIn: NSRect(x: 13.5, y: dy, width: 2, height: 2)).fill()
            }

            return true
        }
        img.isTemplate = (state == .normal)
        return img
    }
}
