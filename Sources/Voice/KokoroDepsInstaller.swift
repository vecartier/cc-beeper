import Foundation

@MainActor
final class KokoroDepsInstaller: ObservableObject {
    @Published var isInstalling: Bool = false
    @Published var installProgress: String = ""
    @Published var installError: String?

    private static let venvPython = AppConstants.kokoroVenvPython

    /// Check if language deps are installed (runs python -c "import module" and checks exit code).
    func areDepsInstalled(for langCode: String) async -> Bool {
        guard langCode == "j" || langCode == "z" else { return true }
        let checkModule = langCode == "j" ? "pyopenjtalk" : "jieba"
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: Self.venvPython)
            process.arguments = ["-c", "import \(checkModule)"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { p in
                continuation.resume(returning: p.terminationStatus == 0)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }
    }

    /// Install language-specific dependencies. For Japanese, runs two steps:
    /// 1. pip install "misaki[ja]"
    /// 2. python -m unidic download (502MB dictionary)
    /// For Chinese: pip install "misaki[zh]" (~45MB)
    func installDeps(for langCode: String) async -> Bool {
        guard langCode == "j" || langCode == "z" else { return true }

        await MainActor.run {
            isInstalling = true
            installProgress = "Installing dependencies..."
            installError = nil
        }

        let package = langCode == "j" ? "misaki[ja]" : "misaki[zh]"

        // Step 1: pip install
        let pipSuccess = await runProcess(
            args: ["-m", "pip", "install", package],
            progressLabel: "Installing \(package)..."
        )
        guard pipSuccess else {
            await MainActor.run {
                isInstalling = false
                installError = "Failed to install \(package)"
            }
            return false
        }

        // Step 2: For Japanese, download unidic dictionary (~502MB)
        if langCode == "j" {
            let unidic = await runProcess(
                args: ["-m", "unidic", "download"],
                progressLabel: "Downloading Japanese dictionary (~500 MB)..."
            )
            guard unidic else {
                await MainActor.run {
                    isInstalling = false
                    installError = "Failed to download Japanese dictionary"
                }
                return false
            }
        }

        await MainActor.run {
            isInstalling = false
            installProgress = "Done"
        }
        return true
    }

    private func runProcess(args: [String], progressLabel: String) async -> Bool {
        await MainActor.run { installProgress = progressLabel }
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: Self.venvPython)
            process.arguments = args
            process.standardOutput = FileHandle.nullDevice

            let stderrPipe = Pipe()
            process.standardError = stderrPipe
            stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !line.isEmpty {
                    Task { @MainActor in
                        self?.installProgress = String(line.suffix(80))
                    }
                }
            }

            process.terminationHandler = { p in
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(returning: p.terminationStatus == 0)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }
    }
}
