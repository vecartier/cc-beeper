import Foundation
import AppKit
import ApplicationServices
import AVFoundation
import Speech

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isAccessibilityGranted: Bool = false
    @Published var isMicGranted: Bool = false
    @Published var isSpeechGranted: Bool = false

    private var pollTimer: Timer?

    func startPolling() {
        refreshPermissionStatus()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPermissionStatus()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func refreshPermissionStatus() {
        isAccessibilityGranted = AXIsProcessTrusted()
        isMicGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        isSpeechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Deep Links

    private func openPrivacyPane(_ anchor: String) {
        // Try multiple URL formats — macOS 26 ignores anchors in some formats
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(anchor)",
            "x-apple.systempreferences:com.apple.preference.security?\(anchor)",
        ]
        for urlString in urls {
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }

    func openAccessibilitySettings() { openPrivacyPane("Privacy_Accessibility") }
    func openMicrophoneSettings() { openPrivacyPane("Privacy_Microphone") }
    func openSpeechSettings() { openPrivacyPane("Privacy_SpeechRecognition") }
    func openSpokenContent() { openPrivacyPane("Privacy_Accessibility") }
}
