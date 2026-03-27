import SwiftUI
import Carbon.HIToolbox

struct ShortcutsWindow: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                ShortcutCategory(title: "Global Hotkeys", subtitle: "Work from any app") {
                    ShortcutRow(action: "Accept Permission", keys: "⌥ \(keyCodeToString(monitor.hotkeyAccept))")
                    ShortcutRow(action: "Deny Permission", keys: "⌥ \(keyCodeToString(monitor.hotkeyDeny))")
                    ShortcutRow(action: "Voice Record", keys: "⌥ \(keyCodeToString(monitor.hotkeyVoice))")
                    ShortcutRow(action: "Go to Terminal", keys: "⌥ \(keyCodeToString(monitor.hotkeyTerminal))")
                    ShortcutRow(action: "VoiceOver / Stop", keys: "⌥ \(keyCodeToString(monitor.hotkeyMute))")
                }
            }

            Text("Hotkeys can be remapped in Settings > Hotkeys.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 360)
    }
}

// MARK: - Components

private struct ShortcutCategory<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 1) {
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct ShortcutRow: View {
    let action: String
    let keys: String

    var body: some View {
        HStack {
            Text(action)
                .font(.body)
            Spacer()
            Text(keys)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quinary)
    }
}
