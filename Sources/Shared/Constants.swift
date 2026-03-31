import SwiftUI

/// Canonical definitions for values used across multiple files (FRAG-06, FRAG-07, FRAG-08).
enum AppConstants {

    // MARK: - Terminal Bundle IDs (FRAG-06)

    /// Terminals supported for focus, injection safety, and "go to conversation".
    static let terminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "io.alacritty",
        "net.kovidgoyal.kitty",
        "com.github.wez.wezterm",
    ]

    // MARK: - Kokoro Paths (FRAG-08)

    /// Python interpreter inside the Kokoro TTS virtual environment.
    static let kokoroVenvPython = NSHomeDirectory() + "/.cache/cc-beeper/kokoro-venv/bin/python3"

    // MARK: - LED Colors (FRAG-07)

    /// Green LED color (idle/done states).
    static let ledGreen = Color(hex: "4ADE80")

    /// Amber LED color (working/attention states).
    static let ledAmber = Color(hex: "FACC15")

    /// LED off color.
    static let ledOff = Color(white: 0.35)

    // MARK: - LCD Overlay Colors (FRAG-07)

    /// LCD vignette / inner shadow dark tint.
    static let lcdShadowTint = Color(hex: "1A3008")

    /// LCD pixel grid line color.
    static let lcdGridLine = Color(hex: "2A4A10")
}
