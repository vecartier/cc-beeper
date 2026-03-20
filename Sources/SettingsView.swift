import SwiftUI
import ApplicationServices

// MARK: - Root Settings View

@available(macOS 15.0, *)
struct SettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralSettingsView()
            }
            Tab("Appearance", systemImage: "paintbrush") {
                AppearanceSettingsView()
            }
            Tab("AI", systemImage: "cpu") {
                AISettingsView()
            }
            Tab("Privacy", systemImage: "lock.shield") {
                PrivacySettingsView()
            }
        }
        .frame(width: 550, height: 400)
    }
}

// MARK: - General Settings

@available(macOS 15.0, *)
struct GeneralSettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @State private var axTrusted: Bool = AXIsProcessTrusted()

    var body: some View {
        Form {
            Section("Sound") {
                Toggle("Enable sounds", isOn: $monitor.soundEnabled)
            }

            Section("Notifications") {
                Toggle("Enable notifications", isOn: $monitor.notificationsEnabled)
            }

            Section("Global Hotkeys") {
                if axTrusted {
                    Text("Option+A to allow, Option+D to deny")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility access is required for global hotkeys.")
                            .foregroundStyle(.secondary)
                        Button("Grant Accessibility Access") {
                            let opts = [
                                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
                            ] as CFDictionary
                            axTrusted = AXIsProcessTrustedWithOptions(opts)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            axTrusted = AXIsProcessTrusted()
        }
    }
}

// MARK: - Appearance Settings

@available(macOS 15.0, *)
struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Color Theme", selection: $themeManager.currentThemeId) {
                    ForEach(ThemeManager.themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Mode") {
                Toggle("Dark Mode", isOn: $themeManager.darkMode)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - AI Settings

@available(macOS 15.0, *)
private enum ValidationState: Equatable {
    case idle
    case validating
    case valid
    case invalid(String)
    case error(String)
}

@available(macOS 15.0, *)
struct AISettingsView: View {
    @EnvironmentObject var monitor: ClaudeMonitor

    @State private var selectedProvider: APIProvider = .anthropic
    @State private var apiKeyText: String = ""
    @State private var isRevealed: Bool = false
    @FocusState private var keyFieldFocused: Bool
    @State private var validationState: ValidationState = .idle
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(APIProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedProvider) { _, newProvider in
                    apiKeyText = KeychainHelper.load(key: newProvider.keychainKey) ?? ""
                    validationState = .idle
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Group {
                            if isRevealed {
                                TextField("Paste API key", text: $apiKeyText)
                                    .focused($keyFieldFocused)
                            } else {
                                SecureField("Paste API key", text: $apiKeyText)
                                    .focused($keyFieldFocused)
                            }
                        }
                        .textFieldStyle(.plain)

                        Button {
                            isRevealed.toggle()
                            keyFieldFocused = true
                        } label: {
                            Image(systemName: isRevealed ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Stored in macOS Keychain")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    validationFeedback
                }
            } header: {
                Text("API Key")
            }

            Section {
                HStack {
                    Button("Save") {
                        let success = KeychainHelper.save(apiKeyText, key: selectedProvider.keychainKey)
                        if success {
                            validationState = .valid
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                validationState = .idle
                            }
                        }
                    }
                    .disabled(apiKeyText.isEmpty)

                    Button("Test") {
                        validationState = .validating
                        Task {
                            let result = await APIKeyValidator.validate(
                                key: apiKeyText,
                                provider: selectedProvider
                            )
                            switch result {
                            case .valid:
                                validationState = .valid
                            case .invalid(let message):
                                validationState = .invalid(message)
                            case .networkError(let message):
                                validationState = .error(message)
                            }
                        }
                    }
                    .disabled(apiKeyText.isEmpty)

                    Button("Clear") {
                        showDeleteConfirm = true
                    }
                    .foregroundStyle(.red)
                    .disabled(apiKeyText.isEmpty)
                    .confirmationDialog(
                        "Remove API Key?",
                        isPresented: $showDeleteConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Remove", role: .destructive) {
                            _ = KeychainHelper.delete(key: selectedProvider.keychainKey)
                            apiKeyText = ""
                            validationState = .idle
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("The \(selectedProvider.rawValue) API key will be removed from your Keychain.")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            apiKeyText = KeychainHelper.load(key: selectedProvider.keychainKey) ?? ""
        }
    }

    @ViewBuilder
    private var validationFeedback: some View {
        switch validationState {
        case .idle:
            EmptyView()
        case .validating:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Validating...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .valid:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Valid")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        case .invalid(let message):
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        case .error(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Privacy Settings

@available(macOS 15.0, *)
struct PrivacySettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Privacy")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Your data never leaves your Mac. We don't run servers. Everything stays local.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                privacySection(
                    title: "API Keys",
                    body: "API keys are stored in macOS Keychain, Apple's secure credential storage. They are never transmitted anywhere except directly to the provider you choose (Anthropic or OpenAI)."
                )

                privacySection(
                    title: "Voice Input",
                    body: "Voice transcription uses Apple's on-device speech recognition. No audio leaves your Mac — transcription happens entirely on your device."
                )

                privacySection(
                    title: "Monitoring Data",
                    body: "All Claude session monitoring data stays in ~/.claude/claumagotchi/ on your local filesystem. Nothing is uploaded. No analytics are collected."
                )

                privacySection(
                    title: "No Servers. No Accounts.",
                    body: "Claumagotchi has no backend, no user accounts, and no telemetry. There is nothing to track and nowhere to send it."
                )
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }

    private func privacySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
