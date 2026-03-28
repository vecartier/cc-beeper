import Foundation

/// Model size options for on-device Whisper transcription via WhisperKit.
///
/// The selected size is persisted in UserDefaults and used by WhisperService
/// to determine which CoreML model to download and load.
enum WhisperModelSize: String, CaseIterable, Sendable {
    case small = "small"
    case medium = "medium"

    var modelName: String {
        switch self {
        case .small: return "openai_whisper-small"
        case .medium: return "openai_whisper-medium"
        }
    }

    var displayLabel: String {
        switch self {
        case .small: return "Small (~500 MB) — Recommended"
        case .medium: return "Medium (~1.5 GB) — Higher accuracy"
        }
    }

    /// UserDefaults key for persisting selection
    static var selected: WhisperModelSize {
        let raw = UserDefaults.standard.string(forKey: "whisperModelSize") ?? "small"
        return WhisperModelSize(rawValue: raw) ?? .small
    }
}
