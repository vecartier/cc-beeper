import SwiftUI

struct SettingsAboutSection: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

    var body: some View {
        Section {
            VStack(spacing: 12) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                }

                Text("CC-Beeper")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Version \(version) (\(build))")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("A desktop companion for Claude Code.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }

        Section {
            Link(destination: URL(string: "https://github.com/vecartier/cc-beeper")!) {
                Label("GitHub", systemImage: "link")
            }

            Link(destination: URL(string: "https://github.com/vecartier/cc-beeper/releases")!) {
                Label("Releases", systemImage: "arrow.down.circle")
            }

            Link(destination: URL(string: "https://github.com/vecartier/cc-beeper/issues")!) {
                Label("Report an Issue", systemImage: "exclamationmark.bubble")
            }
        }
    }
}
