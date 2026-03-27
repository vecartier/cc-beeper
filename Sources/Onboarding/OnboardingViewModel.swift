import Foundation
import AppKit
import ApplicationServices
import AVFoundation
import Speech

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome = 0
        case cliAndHooks = 1
        case permissions = 2
        case modelDownload = 3
        case done = 4
    }

    @Published var currentStep: Step = .welcome
    @Published var isClaudeDetected: Bool = false
    @Published var isHooksInstalled: Bool = false
    @Published var hookInstallError: String? = nil
    @Published var isAccessibilityGranted: Bool = false
    @Published var isMicGranted: Bool = false
    @Published var isSpeechGranted: Bool = false

    // MARK: - Model Download State
    @Published var modelDownloadProgress: Double = 0
    @Published var modelDownloadPhase: String = ""
    @Published var isModelDownloading: Bool = false
    @Published var isModelReady: Bool = false

    var totalSteps: Int { Step.allCases.count }
    var progress: Double { Double(currentStep.rawValue) / Double(totalSteps - 1) }

    private var pollTimer: Timer?

    init() {
        isModelReady = ParakeetService.modelsDownloaded && PocketTTSService.modelsDownloaded
    }

    // MARK: - Navigation

    func goNext() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func goBack() {
        guard let prev = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    // MARK: - Model Download

    func downloadModels() {
        guard !isModelDownloading else { return }
        isModelDownloading = true
        modelDownloadProgress = 0
        modelDownloadPhase = "Preparing..."

        Task {
            // Phase 1: Parakeet (0–50%)
            do {
                try await ParakeetService.shared.downloadModels { [weak self] fraction, label in
                    Task { @MainActor in
                        self?.modelDownloadProgress = fraction * 0.5
                        self?.modelDownloadPhase = "Speech recognition: \(label)"
                    }
                }
            } catch {
                await MainActor.run {
                    self.modelDownloadPhase = "Speech recognition failed — continuing with voice synthesis"
                }
            }

            // Phase 2: PocketTTS (50–100%)
            do {
                try await PocketTTSService.shared.downloadModels { [weak self] fraction, label in
                    Task { @MainActor in
                        self?.modelDownloadProgress = 0.5 + fraction * 0.5
                        self?.modelDownloadPhase = "Voice synthesis: \(label)"
                    }
                }
            } catch {
                await MainActor.run {
                    self.modelDownloadPhase = "Voice download failed — will use Apple voice"
                }
            }

            await MainActor.run {
                self.isModelReady = true
                self.isModelDownloading = false
                self.modelDownloadPhase = "Ready"
            }
        }
    }

    // MARK: - CLI Detection (called on step 1 appear)

    func detectClaude() {
        isClaudeDetected = ClaudeDetector.isInstalled
        isHooksInstalled = HookInstaller.isInstalled
    }

    // MARK: - Hook Installation (one-shot, called on button tap)

    func installHooks() {
        hookInstallError = nil
        do {
            try HookInstaller.install()
            isHooksInstalled = true
        } catch {
            hookInstallError = error.localizedDescription
        }
    }

    // MARK: - Permission Polling

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

    // MARK: - Permission Requests (one-shot, on button tap ONLY)

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            Task { @MainActor [weak self] in
                self?.isMicGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            }
        }
    }

    func requestSpeechRecognition() {
        SFSpeechRecognizer.requestAuthorization { _ in
            Task { @MainActor [weak self] in
                self?.isSpeechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
            }
        }
    }

    // MARK: - Deep Links

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func openMicrophoneSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone") else { return }
        NSWorkspace.shared.open(url)
    }

    func openSpeechSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_SpeechRecognition") else { return }
        NSWorkspace.shared.open(url)
    }

    func openSpokenContent() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?SpokenContent") else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Completion

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        stopPolling()
    }

    var allPermissionsGranted: Bool {
        isAccessibilityGranted && isMicGranted && isSpeechGranted
    }
}
