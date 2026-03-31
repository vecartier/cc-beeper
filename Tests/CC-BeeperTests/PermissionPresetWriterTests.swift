import XCTest
import Foundation

/// Tests for PermissionPreset enum contracts and settings.json write logic.
///
/// Note: @testable import is not supported for .executableTarget.
/// These tests replicate the PermissionPreset type and verify the JSON
/// read/write algorithm using temp files.

// MARK: - Replicated Types

/// Mirror of production PermissionPreset — must stay in sync with
/// Sources/Monitor/PermissionPresetWriter.swift.
private enum TestPermissionPreset: String, CaseIterable {
    case cautious, relaxed, trusted, yolo

    /// The value to write to `permissions.defaultMode` in settings.json.
    var defaultModeValue: String? {
        switch self {
        case .cautious, .relaxed, .trusted: return nil
        case .yolo: return "bypassPermissions"
        }
    }

    /// Tools auto-approved by CC-Beeper via hook responses (not written to settings.json).
    var allowedTools: [String]? {
        switch self {
        case .cautious: return nil
        case .relaxed: return ["Read", "Glob", "Grep"]
        case .trusted: return ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"]
        case .yolo: return nil
        }
    }
}

// MARK: - Helpers

/// Applies a TestPermissionPreset to a temp settings file and returns the parsed result.
private func applyPreset(
    _ preset: TestPermissionPreset,
    to settingsPath: String,
    existingContent: [String: Any]? = nil
) throws -> [String: Any] {
    let fm = FileManager.default

    // Write initial content if provided
    if let existing = existingContent {
        let data = try JSONSerialization.data(withJSONObject: existing, options: [.prettyPrinted])
        try data.write(to: URL(fileURLWithPath: settingsPath))
    }

    // Replicate the PermissionPresetWriter.applyPreset algorithm
    var settings: [String: Any] = [:]
    if fm.fileExists(atPath: settingsPath),
       let data = fm.contents(atPath: settingsPath),
       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        settings = parsed
    }

    // Get or create permissions object
    var perms = settings["permissions"] as? [String: Any] ?? [:]

    if let mode = preset.defaultModeValue {
        perms["defaultMode"] = mode
    } else {
        perms.removeValue(forKey: "defaultMode")
    }

    settings["permissions"] = perms

    // Clean up legacy fields
    settings.removeValue(forKey: "permission_mode")
    settings.removeValue(forKey: "allowedTools")

    let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted])

    let tmpPath = settingsPath + ".tmp"
    try data.write(to: URL(fileURLWithPath: tmpPath))
    if fm.fileExists(atPath: settingsPath) {
        _ = try fm.replaceItemAt(
            URL(fileURLWithPath: settingsPath),
            withItemAt: URL(fileURLWithPath: tmpPath)
        )
    } else {
        try fm.moveItem(atPath: tmpPath, toPath: settingsPath)
    }

    guard let result = fm.contents(atPath: settingsPath),
          let parsed = try? JSONSerialization.jsonObject(with: result) as? [String: Any] else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read written file"])
    }
    return parsed
}

/// Replicates the readCurrentPreset fallback logic (settings.json only, no UserDefaults).
private func readPreset(from settingsPath: String) -> TestPermissionPreset {
    let fm = FileManager.default
    guard fm.fileExists(atPath: settingsPath),
          let data = fm.contents(atPath: settingsPath),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return .cautious
    }

    // Check permissions.defaultMode
    if let perms = json["permissions"] as? [String: Any],
       let mode = perms["defaultMode"] as? String,
       mode == "bypassPermissions" {
        return .yolo
    }

    // Legacy fallback
    if let mode = json["permission_mode"] as? String, mode == "bypass" {
        return .yolo
    }

    return .cautious
}

/// Replicates the PermissionPresetWriter.isSettingsMalformed algorithm from a file path.
private func isMalformed(at settingsPath: String) -> Bool {
    let fm = FileManager.default
    guard fm.fileExists(atPath: settingsPath),
          let data = fm.contents(atPath: settingsPath) else {
        return false
    }
    return (try? JSONSerialization.jsonObject(with: data)) == nil
}

// MARK: - PermissionPresetWriterTests

final class PermissionPresetWriterTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: 1. Enum shape

    func testPresetEnumHasFourCases() {
        XCTAssertEqual(TestPermissionPreset.allCases.count, 4)
    }

    // MARK: 2. Write: cautious — no defaultMode, no legacy fields

    func testCautiousWritesNoDefaultMode() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.cautious, to: path)

        let perms = result["permissions"] as? [String: Any] ?? [:]
        XCTAssertNil(perms["defaultMode"], "cautious should not set defaultMode")
        XCTAssertNil(result["permission_mode"], "legacy permission_mode should be removed")
        XCTAssertNil(result["allowedTools"], "legacy allowedTools should be removed")
    }

    // MARK: 3. Write: relaxed — no defaultMode (hooks handle auto-approve)

    func testRelaxedWritesNoDefaultMode() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.relaxed, to: path)

        let perms = result["permissions"] as? [String: Any] ?? [:]
        XCTAssertNil(perms["defaultMode"], "relaxed should not set defaultMode")
        XCTAssertNil(result["allowedTools"], "allowedTools should not be in settings.json")
    }

    // MARK: 4. Write: trusted — no defaultMode (hooks handle auto-approve)

    func testTrustedWritesNoDefaultMode() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.trusted, to: path)

        let perms = result["permissions"] as? [String: Any] ?? [:]
        XCTAssertNil(perms["defaultMode"], "trusted should not set defaultMode")
        XCTAssertNil(result["allowedTools"], "allowedTools should not be in settings.json")
    }

    // MARK: 5. Write: yolo — sets bypassPermissions

    func testYoloWritesBypassPermissions() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let result = try applyPreset(.yolo, to: path)

        let perms = result["permissions"] as? [String: Any] ?? [:]
        XCTAssertEqual(perms["defaultMode"] as? String, "bypassPermissions")
        XCTAssertNil(result["permission_mode"], "legacy permission_mode should be removed")
    }

    // MARK: 6. Preserve other fields

    func testAtomicWritePreservesOtherFields() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let initial: [String: Any] = [
            "hooks": ["PreToolUse": []],
            "customField": "keep",
            "permissions": ["allow": ["Bash(npm test)"]],
        ]
        let result = try applyPreset(.relaxed, to: path, existingContent: initial)

        // Other fields preserved
        XCTAssertNotNil(result["hooks"], "hooks key should be preserved")
        XCTAssertEqual(result["customField"] as? String, "keep", "customField should be preserved")

        // Existing permissions.allow preserved
        let perms = result["permissions"] as? [String: Any] ?? [:]
        let allow = perms["allow"] as? [String] ?? []
        XCTAssertTrue(allow.contains("Bash(npm test)"), "existing permissions.allow should be preserved")
    }

    // MARK: 7. Legacy cleanup — removes old fields

    func testLegacyFieldsRemovedOnWrite() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let initial: [String: Any] = [
            "permission_mode": "bypass",
            "allowedTools": ["Read", "Glob"],
        ]
        let result = try applyPreset(.cautious, to: path, existingContent: initial)

        XCTAssertNil(result["permission_mode"], "legacy permission_mode should be removed")
        XCTAssertNil(result["allowedTools"], "legacy allowedTools should be removed")
    }

    // MARK: 8. Malformed detection: invalid JSON

    func testMalformedJsonDetection() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let invalidContent = "{ this is not valid json !!!".data(using: .utf8)!
        try invalidContent.write(to: URL(fileURLWithPath: path))

        XCTAssertTrue(isMalformed(at: path), "Malformed JSON should be detected")
    }

    // MARK: 9. Malformed detection: valid JSON

    func testValidJsonNotMalformed() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let validContent: [String: Any] = ["permissions": ["defaultMode": "default"]]
        let data = try JSONSerialization.data(withJSONObject: validContent)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertFalse(isMalformed(at: path), "Valid JSON should not be flagged as malformed")
    }

    // MARK: 10. Read: bypassPermissions → yolo

    func testReadCurrentPresetFromBypassPermissions() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let content: [String: Any] = ["permissions": ["defaultMode": "bypassPermissions"]]
        let data = try JSONSerialization.data(withJSONObject: content)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertEqual(readPreset(from: path), .yolo)
    }

    // MARK: 11. Read: legacy bypass → yolo (migration)

    func testReadCurrentPresetFromLegacyBypass() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let content: [String: Any] = ["permission_mode": "bypass"]
        let data = try JSONSerialization.data(withJSONObject: content)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertEqual(readPreset(from: path), .yolo)
    }

    // MARK: 12. Read: empty JSON → cautious

    func testReadCurrentPresetDefaultsToCautious() throws {
        let path = tempDir.appendingPathComponent("settings.json").path
        let content: [String: Any] = [:]
        let data = try JSONSerialization.data(withJSONObject: content)
        try data.write(to: URL(fileURLWithPath: path))

        XCTAssertEqual(readPreset(from: path), .cautious)
    }

    // MARK: 13. AskUserQuestion classification

    func testAskUserQuestionClassifiedAsInput() {
        let hookEventName = "PermissionRequest"
        let toolName = "AskUserQuestion"

        let isAskUserQuestion = (hookEventName == "PermissionRequest" && toolName == "AskUserQuestion")
        let classification = isAskUserQuestion ? "input" : "permission"

        XCTAssertEqual(classification, "input",
            "AskUserQuestion in PermissionRequest should classify as input, not permission")

        let otherTool = "Bash"
        let isOtherQuestion = (hookEventName == "PermissionRequest" && otherTool == "AskUserQuestion")
        let otherClassification = isOtherQuestion ? "input" : "permission"
        XCTAssertEqual(otherClassification, "permission",
            "Bash in PermissionRequest should classify as permission")
    }

    // MARK: 14. allowedTools enum values (hook-side only)

    func testAllowedToolsForPresets() {
        XCTAssertNil(TestPermissionPreset.cautious.allowedTools)
        XCTAssertEqual(TestPermissionPreset.relaxed.allowedTools, ["Read", "Glob", "Grep"])
        XCTAssertEqual(TestPermissionPreset.trusted.allowedTools, ["Read", "Glob", "Grep", "Write", "Edit", "NotebookEdit"])
        XCTAssertNil(TestPermissionPreset.yolo.allowedTools)
    }
}
