import SwiftUI

// MARK: - Pixel Title

struct PixelTitle: View {
    @EnvironmentObject var themeManager: ThemeManager

    private let px: CGFloat = 1.4
    private let gap: CGFloat = 1.0

    // Rounded, playful letterforms — used for LCD title display
    private static let font: [Character: [String]] = [
        "C": [".###.", "#...#", "#....", "#....", "#...#", ".###."],
        "L": ["#....", "#....", "#....", "#....", "#....", "#####"],
        "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#"],
        "U": ["#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
        "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#"],
        "G": [".###.", "#....", "#.###", "#...#", "#...#", ".###."],
        "O": [".###.", "#...#", "#...#", "#...#", "#...#", ".###."],
        "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#.."],
        "H": ["#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
        "I": [".#.", ".#.", ".#.", ".#.", ".#.", ".#."],
        "B": ["####.", "#...#", "#...#", "####.", "#...#", "####."],
        "E": ["#####", "#....", "#....", "####.", "#....", "#####"],
        "P": ["####.", "#...#", "#...#", "####.", "#....", "#...."],
        "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..##"],
        "-": [".....", ".....", "#####", "#####", ".....", "....."],
    ]

    var body: some View {
        Canvas { context, size in
            let color = themeManager.lcdOn
            let highlight = themeManager.lcdOn.opacity(0.4)
            let shadow = themeManager.lcdOn.opacity(0.2)

            let text: [Character] = Array("CC-BEEPER")

            var totalW: CGFloat = 0
            for ch in text {
                if let g = Self.font[ch] {
                    totalW += CGFloat(g[0].count) * px + gap
                }
            }
            totalW -= gap

            var x = (size.width - totalW) / 2
            let y = (size.height - 6 * px) / 2

            // Shadow pass (down-right)
            for ch in text {
                guard let glyph = Self.font[ch] else { continue }
                let w = CGFloat(glyph[0].count)
                for (row, line) in glyph.enumerated() {
                    for (col, p) in line.enumerated() where p == "#" {
                        let rect = CGRect(
                            x: x + CGFloat(col) * px + 1,
                            y: y + CGFloat(row) * px + 1,
                            width: px, height: px
                        )
                        context.fill(Path(rect), with: .color(shadow))
                    }
                }
                x += w * px + gap
            }

            // Highlight pass (up-left)
            x = (size.width - totalW) / 2
            for ch in text {
                guard let glyph = Self.font[ch] else { continue }
                let w = CGFloat(glyph[0].count)
                for (row, line) in glyph.enumerated() {
                    for (col, p) in line.enumerated() where p == "#" {
                        let rect = CGRect(
                            x: x + CGFloat(col) * px - 0.4,
                            y: y + CGFloat(row) * px - 0.4,
                            width: px, height: px
                        )
                        context.fill(Path(rect), with: .color(highlight.opacity(0.4)))
                    }
                }
                x += w * px + gap
            }

            // Main pass
            x = (size.width - totalW) / 2
            for ch in text {
                guard let glyph = Self.font[ch] else { continue }
                let w = CGFloat(glyph[0].count)
                for (row, line) in glyph.enumerated() {
                    for (col, p) in line.enumerated() where p == "#" {
                        let rect = CGRect(
                            x: x + CGFloat(col) * px,
                            y: y + CGFloat(row) * px,
                            width: px, height: px
                        )
                        context.fill(Path(rect), with: .color(color))
                    }
                }
                x += w * px + gap
            }
        }
    }
}
