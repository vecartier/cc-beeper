import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case theme = "Theme"
    case voice = "Voice Record"
    case voiceOver = "Voice Reader"
    case feedback = "Feedback"
    case hotkeys = "Hotkeys"
    case permissions = "Permissions"
    case setup = "Setup"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .theme: return "paintpalette.fill"
        case .voice: return "waveform"
        case .voiceOver: return "speaker.wave.2.fill"
        case .feedback: return "bell.fill"
        case .hotkeys: return "keyboard.fill"
        case .permissions: return "lock.shield.fill"
        case .setup: return "wrench.and.screwdriver.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedTab: SettingsTab = .theme

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label {
                    Text(tab.rawValue)
                        .font(.body)
                } icon: {
                    Image(systemName: tab.icon)
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 4)
                .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 220)
        } detail: {
            Form {
                switch selectedTab {
                case .theme:
                    SettingsThemeSection()
                case .voice:
                    SettingsVoiceSection()
                case .voiceOver:
                    SettingsVoiceOverSection()
                case .feedback:
                    SettingsFeedbackSection()
                case .hotkeys:
                    SettingsHotkeysSection()
                case .permissions:
                    SettingsPermissionsSection(viewModel: viewModel)
                case .setup:
                    SettingsSetupSection()
                case .about:
                    SettingsAboutSection()
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.visible)
            .font(.body)
        }
        .frame(width: 640, height: 480)
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }
}
