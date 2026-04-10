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
        case theme = 2
        case sizes = 3
        case mode = 4
        case permissions = 5
        case stt = 6
        case tts = 7
        case hotkeys = 8
        case done = 9

        /// 1-based counter position (nil for splash screens: welcome, done).
        var countedNumber: Int? {
            switch self {
            case .welcome, .done: return nil
            case .cliAndHooks: return 1
            case .theme: return 2
            case .sizes: return 3
            case .mode: return 4
            case .permissions: return 5
            case .stt: return 6
            case .tts: return 7
            case .hotkeys: return 8
            }
        }

        var isSplash: Bool { self == .welcome || self == .done }
    }

    /// Total number of counted steps (splashes excluded).
    static let totalCountedSteps: Int = 8

    @Published var currentStep: Step = .welcome
    @Published var isClaudeDetected: Bool = false
    @Published var isHooksInstalled: Bool = false
    @Published var hookInstallError: String? = nil
    @Published var isAccessibilityGranted: Bool = false
    @Published var isMicGranted: Bool = false
    @Published var isSpeechGranted: Bool = false

    // MARK: - Theme & Size State
    @Published var selectedThemeId: String
    @Published var selectedSize: WidgetSize

    // MARK: - Mode State
    @Published var selectedPreset: PermissionPreset

    // MARK: - Model Download State
    @Published var modelDownloadProgress: Double = 0
    @Published var modelDownloadPhase: String = ""
    @Published var isModelDownloading: Bool = false
    @Published var isModelReady: Bool = false

    // Separate STT/TTS download state
    @Published var isSttDownloading: Bool = false
    @Published var isSttReady: Bool = WhisperService.modelsDownloaded
    @Published var isTtsDownloading: Bool = false
    @Published var isTtsReady: Bool = KokoroService.modelsDownloaded
    @Published var ttsDownloadError: String? = nil

    // MARK: - Voice Engine Selection
    @Published var sttProvider: String = "whisper"  // "whisper" or "apple"
    @Published var ttsProvider: String = UserDefaults.standard.string(forKey: "ttsProvider") ?? "kokoro" {
        didSet { UserDefaults.standard.set(ttsProvider, forKey: "ttsProvider") }
    }

    // MARK: - Language Selection State
    @Published var selectedLangCode: String = "a"

    // MARK: - Hotkey State
    @Published var hotkeyAccept: String
    @Published var hotkeyDeny: String
    @Published var hotkeyVoice: String
    @Published var hotkeyTerminal: String
    @Published var hotkeyMute: String

    var totalSteps: Int { Step.allCases.count }
    var progress: Double { Double(currentStep.rawValue) / Double(totalSteps - 1) }

    /// Progress bar fill shown on the splash-aware shell:
    /// 0 on welcome, 1.0 on done, fractional on counted steps.
    var displayProgress: Double {
        if currentStep == .welcome { return 0 }
        if currentStep == .done { return 1 }
        guard let n = currentStep.countedNumber else { return 0 }
        return Double(n) / Double(Self.totalCountedSteps)
    }

    private var pollTimer: Timer?

    init() {
        isModelReady = WhisperService.modelsDownloaded && KokoroService.modelsDownloaded

        // Load current preferences or defaults
        selectedThemeId = UserDefaults.standard.string(forKey: "themeId") ?? "black"
        selectedSize = WidgetSize(rawValue: UserDefaults.standard.string(forKey: "widgetSize") ?? "") ?? .large
        selectedPreset = PermissionPresetWriter.readCurrentPreset()

        hotkeyAccept = UserDefaults.standard.string(forKey: "hotkeyChar_accept") ?? "A"
        hotkeyDeny = UserDefaults.standard.string(forKey: "hotkeyChar_deny") ?? "D"
        hotkeyVoice = UserDefaults.standard.string(forKey: "hotkeyChar_voice") ?? "R"
        hotkeyTerminal = UserDefaults.standard.string(forKey: "hotkeyChar_terminal") ?? "T"
        hotkeyMute = UserDefaults.standard.string(forKey: "hotkeyChar_mute") ?? "M"

        selectedLangCode = UserDefaults.standard.string(forKey: "kokoroLangCode") ?? "b"
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

    // MARK: - Theme & Size

    func applyThemeAndSize() {
        UserDefaults.standard.set(selectedThemeId, forKey: "themeId")
        UserDefaults.standard.set(selectedSize.rawValue, forKey: "widgetSize")
    }

    // MARK: - Mode

    func applyMode() {
        try? PermissionPresetWriter.applyPreset(selectedPreset)
    }

    // MARK: - Model Download

    func downloadModels() {
        guard !isModelDownloading else { return }
        isModelDownloading = true
        modelDownloadProgress = 0
        modelDownloadPhase = "Preparing..."

        Task {
            // Phase 1: Whisper (0–50%)
            do {
                try await WhisperService.shared.downloadModel(size: .selected) { [weak self] fraction, label in
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

            // Phase 2: Kokoro (50–100%)
            do {
                try await KokoroService.shared.downloadModels { [weak self] fraction, label in
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

    func downloadWhisper() {
        guard !isSttDownloading else { return }
        isSttDownloading = true
        Task {
            do {
                try await WhisperService.shared.downloadModel(size: .selected) { _, _ in }
            } catch {}
            await MainActor.run {
                self.isSttReady = true
                self.isSttDownloading = false
            }
        }
    }

    func downloadKokoro() {
        guard !isTtsDownloading else { return }
        isTtsDownloading = true
        ttsDownloadError = nil
        Task {
            var success = false
            do {
                try await KokoroService.shared.downloadModels { _, _ in }
                success = true
            } catch {
                await MainActor.run {
                    self.ttsDownloadError = error.localizedDescription
                }
            }
            await MainActor.run {
                self.isTtsReady = success && KokoroService.modelsDownloaded
                self.isTtsDownloading = false
            }
        }
    }

    // MARK: - CLI Detection

    func detectClaude() {
        isClaudeDetected = ClaudeDetector.isInstalled
        isHooksInstalled = HookInstaller.isInstalled
    }

    // MARK: - Hook Installation

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

    // MARK: - Permission Requests

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

    // MARK: - Language Selection

    func applyLanguageChoice() {
        UserDefaults.standard.set(selectedLangCode, forKey: "kokoroLangCode")
        UserDefaults.standard.set(KokoroVoiceCatalog.defaultVoice(for: selectedLangCode), forKey: "kokoroVoice")
    }

    // MARK: - Hotkeys

    func applyHotkeys() {
        UserDefaults.standard.set(hotkeyAccept, forKey: "hotkeyChar_accept")
        UserDefaults.standard.set(hotkeyDeny, forKey: "hotkeyChar_deny")
        UserDefaults.standard.set(hotkeyVoice, forKey: "hotkeyChar_voice")
        UserDefaults.standard.set(hotkeyTerminal, forKey: "hotkeyChar_terminal")
        UserDefaults.standard.set(hotkeyMute, forKey: "hotkeyChar_mute")
    }

    // MARK: - Completion

    func completeOnboarding() {
        applyThemeAndSize()
        applyMode()
        applyLanguageChoice()
        applyHotkeys()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        // Remove saved window frame so SwiftUI doesn't restore the onboarding window
        UserDefaults.standard.removeObject(forKey: "NSWindow Frame onboarding")
        stopPolling()
    }

    var allPermissionsGranted: Bool {
        isAccessibilityGranted && isMicGranted && isSpeechGranted
    }
}
