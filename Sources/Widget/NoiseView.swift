import SwiftUI
import AppKit

// MARK: - Noise Texture

struct NoiseView: View {
    // Render once, cache forever — noise is deterministic (seeded RNG)
    private static let cachedImage: NSImage = {
        let width = 186
        let height = 224
        let step: CGFloat = 1.5
        let img = NSImage(size: NSSize(width: width, height: height))
        img.lockFocus()
        var rng = SeededRNG(seed: 42)
        var y: CGFloat = 0
        while y < CGFloat(height) {
            var x: CGFloat = 0
            while x < CGFloat(width) {
                let val = rng.next()
                if val < 0.45 {
                    NSColor.white.withAlphaComponent(val * 0.7).setFill()
                    NSRect(x: x, y: y, width: step, height: step).fill()
                } else if val > 0.55 {
                    NSColor.black.withAlphaComponent((1.0 - val) * 0.5).setFill()
                    NSRect(x: x, y: y, width: step, height: step).fill()
                }
                x += step
            }
            y += step
        }
        img.unlockFocus()
        return img
    }()

    var body: some View {
        Image(nsImage: Self.cachedImage)
            .resizable()
    }
}

struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state &>> 1) / Double(UInt64.max >> 1)
    }
}

// MARK: - Color Hex

extension Color {
    /// Parse a hex string into (r, g, b) components in 0...1 range.
    static func hexComponents(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        switch cleaned.count {
        case 6:
            return (
                r: Double(int >> 16) / 255,
                g: Double(int >> 8 & 0xFF) / 255,
                b: Double(int & 0xFF) / 255
            )
        default:
            return (r: 0, g: 0, b: 0)
        }
    }

    init(hex: String) {
        let c = Self.hexComponents(hex)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b)
    }
}
