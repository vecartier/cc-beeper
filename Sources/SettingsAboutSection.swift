import SwiftUI

struct SettingsAboutSection: View {
    private let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    var body: some View {
        Text("CC-Beeper v\(version)")
            .font(.callout)

        Link(destination: URL(string: "https://github.com/vecartier/Claumagotchi")!) {
            Label("GitHub Repository", systemImage: "link")
        }
        .font(.callout)
    }
}
