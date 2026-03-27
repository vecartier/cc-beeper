import SwiftUI
import AppKit

struct MenuBarPopoverView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Quick actions — 2x2 grid
            HStack(spacing: 8) {
                QuickActionButton(icon: "bolt.fill", label: "YOLO", isActive: monitor.autoAccept) {
                    monitor.autoAccept.toggle()
                }
                QuickActionButton(icon: monitor.soundEnabled ? "speaker.fill" : "speaker.slash.fill", label: monitor.soundEnabled ? "Sound" : "Muted", isActive: !monitor.soundEnabled) {
                    monitor.soundEnabled.toggle()
                }
                QuickActionButton(icon: "eye.slash", label: "Hide", isActive: false) {
                    CCBeeperApp.toggleMainWindow()
                }
                QuickActionButton(icon: "power", label: monitor.isActive ? "On" : "Off", isActive: monitor.isActive) {
                    monitor.isActive.toggle()
                    if !monitor.isActive {
                        CCBeeperApp.hideMainWindow()
                    } else {
                        CCBeeperApp.showMainWindow()
                    }
                }
            }
            .padding(.bottom, 12)

            Divider().padding(.bottom, 10)

            // Theme
            HStack(spacing: 6) {
                ForEach(ThemeManager.themes) { theme in
                    Circle()
                        .fill(colorForTheme(theme.id))
                        .frame(width: 20, height: 20)
                        .overlay(
                            themeManager.currentThemeId == theme.id ?
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white) : nil
                        )
                        .onTapGesture { themeManager.currentThemeId = theme.id }
                }
            }
            .padding(.bottom, 10)

            Toggle("Dark Mode", isOn: $themeManager.darkMode)
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.callout)
                .padding(.bottom, 10)

            Divider().padding(.bottom, 10)

            // Actions
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            } label: {
                Label("Settings...", systemImage: "gear")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)

            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "onboarding")
            } label: {
                Label("Setup...", systemImage: "wand.and.stars")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.bottom, 10)

            Divider().padding(.bottom, 10)

            Button("Quit CC-Beeper") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.callout)
        }
        .frame(width: 300)
        .padding(16)
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
}
