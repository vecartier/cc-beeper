import SwiftUI
import AppKit

struct MenuBarPopoverView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Quick actions — 2x2 grid like Control Center
            HStack(spacing: 8) {
                QuickActionButton(icon: "bolt.fill", label: "YOLO", isActive: monitor.autoAccept) {
                    monitor.autoAccept.toggle()
                }
                QuickActionButton(icon: monitor.soundEnabled ? "speaker.fill" : "speaker.slash.fill", label: monitor.soundEnabled ? "Sound" : "Muted", isActive: !monitor.soundEnabled) {
                    monitor.soundEnabled.toggle()
                }
                QuickActionButton(icon: "eye.slash", label: "Hide", isActive: false) {
                    ClaumagotchiApp.toggleMainWindow()
                }
                QuickActionButton(icon: "power", label: monitor.isActive ? "On" : "Off", isActive: monitor.isActive) {
                    monitor.isActive.toggle()
                    if !monitor.isActive {
                        ClaumagotchiApp.hideMainWindow()
                    } else {
                        ClaumagotchiApp.showMainWindow()
                    }
                }
            }
            .padding(.bottom, 12)

            Divider().padding(.bottom, 8)

            // Theme
            HStack(spacing: 6) {
                ForEach(ThemeManager.themes) { theme in
                    Circle()
                        .fill(colorForTheme(theme.id))
                        .frame(width: 18, height: 18)
                        .overlay(
                            themeManager.currentThemeId == theme.id ?
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white) : nil
                        )
                        .onTapGesture { themeManager.currentThemeId = theme.id }
                }
            }
            .padding(.bottom, 8)

            Toggle("Dark Mode", isOn: $themeManager.darkMode)
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.bottom, 8)

            Divider().padding(.bottom, 8)

            // Actions
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            } label: {
                Label("Settings...", systemImage: "gear")
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)

            Button {
                openSpokenContent()
            } label: {
                Label("Download Voices...", systemImage: "waveform")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

            Divider().padding(.bottom, 8)

            Button("Quit CC-Beeper") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.footnote)
        }
        .frame(width: 280)
        .padding(14)
    }

    private func colorForTheme(_ id: String) -> Color {
        switch id {
        case "black": return Color(white: 0.15)
        case "blue": return .blue
        case "green": return .green
        case "mint": return .mint
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "white": return Color(white: 0.85)
        case "yellow": return .yellow
        default: return .gray
        }
    }

    private func openSpokenContent() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?SpokenContent") else { return }
        NSWorkspace.shared.open(url)
    }
}
