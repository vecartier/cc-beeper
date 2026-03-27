import SwiftUI

struct ScreenView: View {
    var body: some View {
        ScreenContentView()
    }
}

// MARK: - LCD Status Icon

struct LCDIcon: View {
    let symbol: String
    let active: Bool
    var color: Color = Color(hex: "3A3A2E")

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 7, weight: .bold))
            .foregroundColor(color.opacity(active ? 0.85 : 0.08))
    }
}

// MARK: - Pixel Character

struct PixelCharacterView: View {
    let state: ClaudeState
    let frame: Int
    var onColor: Color = Color(hex: "3A3A2E")
    var isYolo: Bool = false

    private let pixelSize: CGFloat = 2.5

    private var currentSprite: [String] {
        let sprites = isYolo ? [Sprites.yolo1, Sprites.yolo2] : spritesForState(state)
        return sprites[frame % sprites.count]
    }

    var body: some View {
        Canvas { context, size in
            let sprite = currentSprite
            guard let firstRow = sprite.first else { return }
            let cols = firstRow.count, rows = sprite.count
            let totalW = CGFloat(cols) * pixelSize
            let totalH = CGFloat(rows) * pixelSize
            let ox = (size.width - totalW) / 2
            let oy = (size.height - totalH) / 2

            for (row, line) in sprite.enumerated() {
                for (col, char) in line.enumerated() {
                    if char == "#" {
                        let rect = CGRect(
                            x: ox + CGFloat(col) * pixelSize,
                            y: oy + CGFloat(row) * pixelSize,
                            width: pixelSize, height: pixelSize
                        )
                        context.fill(Path(rect), with: .color(onColor))
                    }
                }
            }
        }
    }

    private func spritesForState(_ state: ClaudeState) -> [[String]] {
        switch state {
        case .thinking: [Sprites.thinking1, Sprites.thinking2, Sprites.working1, Sprites.working2]
        case .needsYou: [Sprites.alert1, Sprites.alert2]
        case .finished: [Sprites.happy1, Sprites.happy2]
        case .idle: [Sprites.sleep1, Sprites.sleep2]
        }
    }
}

// MARK: - Sprites (14 wide x 12 tall)

enum Sprites {
    static let thinking1: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#...##..##.#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..............",
        "..##..##..##..",
    ]
    static let thinking2: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.##..##...#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..............",
        "....##..##....",
    ]
    static let working1: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#...####...#.",
        ".#..........#.",
        "############..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]
    static let working2: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#...####...#.",
        ".#..........#.",
        "..############",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]
    static let alert1: [String] = [
        "......##......",
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#...####...#.",
        "..##########..",
        "....######....",
        "..............",
        "..##......##..",
    ]
    static let alert2: [String] = [
        "..............",
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#...####...#.",
        ".#..........#.",
        "..##########..",
        "...#......#...",
        "..##......##..",
    ]
    static let happy1: [String] = [
        ".#...##....#..",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]
    static let happy2: [String] = [
        "..#..##...#...",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..##..##..#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]
    // Sleeping — eyes closed, neutral mouth, gentle breathing animation
    static let sleep1: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..........#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..............",
        "..##......##..",
    ]
    static let sleep2: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#..........#.",
        ".#..........#.",
        ".#....##....#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]
    // YOLO mode — sunglasses character
    static let yolo1: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.####.###.#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "...#......#...",
        "..##......##..",
    ]
    static let yolo2: [String] = [
        "......##......",
        "....######....",
        "..##########..",
        ".#..........#.",
        ".#.###.####.#.",
        ".#..........#.",
        ".#.########.#.",
        ".#..........#.",
        "..##########..",
        "....######....",
        "..............",
        "..##..##..##..",
    ]
}
