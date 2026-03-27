import AppKit

struct AppMover {
    /// Checks if the app is running outside /Applications and prompts the user to move it there.
    ///
    /// Handles three special cases:
    /// - Already in /Applications: returns immediately (no-op).
    /// - Running from an SPM/Xcode build directory: returns immediately (dev build).
    /// - App Translocation (quarantine sandbox): shows guidance message instead of attempting a move.
    ///
    /// For all other locations (DMG, Downloads, Desktop, etc.), shows an NSAlert offering to copy
    /// the app to /Applications. Uses `copyItem` + `removeItem` (not `moveItem`) so it works
    /// cross-volume from a mounted DMG image.
    static func moveToApplicationsIfNeeded() {
        let fm = FileManager.default
        let currentPath = Bundle.main.bundlePath

        // 1. Already in /Applications (or a subdirectory) — nothing to do.
        if currentPath.hasPrefix("/Applications/") { return }

        // 2. Running from an Xcode / SPM build directory — skip during development.
        if currentPath.contains(".build/") { return }

        // 3. App Translocation — macOS quarantine sandboxes apps launched directly from a DMG.
        //    FileManager.moveItem cannot escape the translocated sandbox, so guide the user to
        //    manually copy the app instead.
        if currentPath.contains("AppTranslocation") {
            let alert = NSAlert()
            alert.messageText = "Move CC-Beeper to Applications"
            alert.informativeText = "macOS is running CC-Beeper from a temporary location. " +
                "Please drag CC-Beeper to your Applications folder and reopen it."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        // 4. Prompt the user to copy the app to /Applications.
        let alert = NSAlert()
        alert.messageText = "Move CC-Beeper to Applications?"
        alert.informativeText = "CC-Beeper works best when installed in your Applications folder."
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Don't Move")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let appName = (currentPath as NSString).lastPathComponent
        let targetPath = "/Applications/\(appName)"

        do {
            // Remove existing copy if present
            if fm.fileExists(atPath: targetPath) {
                try fm.removeItem(atPath: targetPath)
            }
            // Use copyItem as the primary operation — works cross-volume from a mounted DMG.
            // moveItem fails with a cross-device link error on different filesystems.
            try fm.copyItem(atPath: currentPath, toPath: targetPath)
            // Remove the source after a successful copy
            try? fm.removeItem(atPath: currentPath)
            // Re-launch from the new location and quit
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: targetPath),
                configuration: NSWorkspace.OpenConfiguration()
            )
            NSApp.terminate(nil)
        } catch {
            // Silent failure — the app still works from its current location.
        }
    }
}
