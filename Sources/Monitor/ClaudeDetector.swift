import Foundation

struct ClaudeDetector {
    /// Returns true when the ~/.claude/ directory exists (soft signal — indicates prior install).
    static var claudeDirExists: Bool {
        FileManager.default.fileExists(atPath: NSHomeDirectory() + "/.claude")
    }

    /// Searches common install locations for the `claude` binary and returns the first found path.
    /// Note: the PATH inside a macOS app is minimal and does NOT include ~/.local/bin,
    /// so we always check hardcoded paths rather than running `which claude`.
    static var claudeBinaryPath: String? {
        let fm = FileManager.default

        // 1. npm global install (most common — Claude Code native installer)
        let npmPath = NSHomeDirectory() + "/.local/bin/claude"
        if fm.fileExists(atPath: npmPath) { return npmPath }

        // 2. Homebrew (Apple Silicon)
        if fm.fileExists(atPath: "/opt/homebrew/bin/claude") { return "/opt/homebrew/bin/claude" }

        // 3. Homebrew (Intel)
        if fm.fileExists(atPath: "/usr/local/bin/claude") { return "/usr/local/bin/claude" }

        // 4. nvm installs — path changes per Node version, so we glob ~/.nvm/versions/node/
        let nvmBase = NSHomeDirectory() + "/.nvm/versions/node"
        if let versions = try? fm.contentsOfDirectory(atPath: nvmBase) {
            for version in versions.sorted(by: >) {  // newest version first
                let candidate = "\(nvmBase)/\(version)/bin/claude"
                if fm.fileExists(atPath: candidate) { return candidate }
            }
        }

        return nil
    }

    /// True if Claude Code appears to be installed (binary found OR ~/.claude/ directory exists).
    static var isInstalled: Bool {
        claudeBinaryPath != nil || claudeDirExists
    }
}
