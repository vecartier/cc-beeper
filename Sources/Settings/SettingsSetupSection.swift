import SwiftUI

struct SettingsSetupSection: View {
    @Environment(\.openWindow) private var openWindow
    @State private var showUninstallConfirmation = false

    var body: some View {
        Section("Setup Wizard") {
            Button("Run Setup Wizard...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "onboarding")
            }

            Text("Re-run to install hooks, grant permissions, or download voice models.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Uninstall") {
            Button("Uninstall CC-Beeper...", role: .destructive) {
                showUninstallConfirmation = true
            }

            Text("Removes the app, hooks, cached models, and configuration files.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .confirmationDialog(
            "Uninstall CC-Beeper?",
            isPresented: $showUninstallConfirmation,
            titleVisibility: .visible
        ) {
            Button("Uninstall", role: .destructive) {
                performUninstall()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove CC-Beeper, its hooks, cached voice models, and configuration. This cannot be undone.")
        }
    }

    private func performUninstall() {
        let script = Bundle.main.bundlePath
            .replacingOccurrences(of: "/CC-Beeper.app", with: "/uninstall.py")
        let fallback = NSHomeDirectory() + "/Desktop/CC-Beeper/uninstall.py"
        let path = FileManager.default.fileExists(atPath: script) ? script : fallback

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [path]
        try? process.run()
        process.waitUntilExit()
        NSApp.terminate(nil)
    }
}
