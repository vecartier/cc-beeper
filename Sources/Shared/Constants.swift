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

    // MARK: - IDE Bundle IDs (IDE-01, IDE-02)

    /// IDEs with integrated terminals that can run Claude Code.
    static let ideBundleIDs: Set<String> = [
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",   // Cursor
        "dev.zed.Zed",
        "com.mitchellh.ghostty",
    ]

    /// JetBrains IDE family (IDE-02).
    static let jetbrainsBundleIDs: Set<String> = [
        "com.jetbrains.intellij",
        "com.jetbrains.WebStorm",
        "com.jetbrains.goland",
        "com.jetbrains.pycharm",
        "com.jetbrains.CLion",
        "com.jetbrains.rider",
        "com.jetbrains.rustrover",
        "com.jetbrains.fleet",
    ]

    /// All apps that can host a Claude Code session (terminals + IDEs).
    static let allFocusableBundleIDs: Set<String> =
        terminalBundleIDs.union(ideBundleIDs).union(jetbrainsBundleIDs)

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
