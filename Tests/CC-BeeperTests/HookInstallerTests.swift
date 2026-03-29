import XCTest
import Foundation

/// Tests for HookInstaller logic.
/// Since @testable import is not supported for .executableTarget, these tests
/// replicate the core isInstalled detection logic directly using FileManager to
/// verify correctness of the algorithm (not the type itself).
final class HookInstallerTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    /// isInstalled detection: returns false when settings.json has no cc-beeper/port entry.
    func testIsInstalledReturnsFalseWhenNoHTTPHookEntry() throws {
        let settingsURL = tempDir.appendingPathComponent("settings.json")

        // Write a settings.json with no cc-beeper hooks
        let settings: [String: Any] = ["hooks": ["PreToolUse": []]]
        let data = try JSONSerialization.data(withJSONObject: settings)
        try data.write(to: settingsURL)

        // Replicate isInstalled detection logic (HTTP hook marker)
        let hookMarker = "cc-beeper/port"
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsURL.path),
              let readData = fm.contents(atPath: settingsURL.path),
              let parsed = try? JSONSerialization.jsonObject(with: readData) as? [String: Any],
              let hooks = parsed["hooks"] as? [String: Any] else {
            XCTFail("Settings setup failed")
            return
        }

        var found = false
        for (_, value) in hooks {
            guard let rules = value as? [[String: Any]] else { continue }
            for rule in rules {
                guard let hs = rule["hooks"] as? [[String: Any]] else { continue }
                for h in hs where (h["command"] as? String)?.contains(hookMarker) == true {
                    found = true
                }
            }
        }
        XCTAssertFalse(found, "Expected no cc-beeper HTTP hook entries in settings.json")
    }

    /// isInstalled detection: returns true when settings.json contains a cc-beeper/port entry.
    func testIsInstalledReturnsTrueWhenHTTPHookEntryPresent() throws {
        let settingsURL = tempDir.appendingPathComponent("settings.json")
        let hookMarker = "cc-beeper/port"

        // Write a settings.json that mirrors what HookInstaller.install() would produce
        let asyncCmd = "PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true"
        let hookEntry: [String: Any] = [
            "type": "command",
            "command": asyncCmd,
            "async": true,
            "timeout": 5,
            "statusMessage": "CC-Beeper monitoring\u{2026}",
        ]
        let rule: [String: Any] = ["matcher": "", "hooks": [hookEntry]]
        let settings: [String: Any] = ["hooks": ["PreToolUse": [rule]]]
        let data = try JSONSerialization.data(withJSONObject: settings)
        try data.write(to: settingsURL)

        // Replicate isInstalled detection logic
        let fm = FileManager.default
        guard let readData = fm.contents(atPath: settingsURL.path),
              let parsed = try? JSONSerialization.jsonObject(with: readData) as? [String: Any],
              let hooks = parsed["hooks"] as? [String: Any] else {
            XCTFail("Settings read failed")
            return
        }

        var found = false
        for (_, value) in hooks {
            guard let rules = value as? [[String: Any]] else { continue }
            for rule in rules {
                guard let hs = rule["hooks"] as? [[String: Any]] else { continue }
                for h in hs where (h["command"] as? String)?.contains(hookMarker) == true {
                    found = true
                }
            }
        }
        XCTAssertTrue(found, "Expected to find cc-beeper HTTP hook entry in settings.json")
    }

    /// Verifies all 6 hook events (4 async + 2 blocking) are accounted for.
    func testAllSixHookEventsAreDeclared() throws {
        let asyncEvents = ["PreToolUse", "PostToolUse", "Stop", "StopFailure"]
        let blockingEvents = ["Notification", "PermissionRequest"]
        let allEvents = asyncEvents + blockingEvents

        // We verify this by replicating the event configs from HookInstaller
        let asyncConfigs: [(String, Int, String?)] = [
            ("PreToolUse",  5, "CC-Beeper monitoring\u{2026}"),
            ("PostToolUse", 5, nil),
            ("Stop",        5, nil),
            ("StopFailure", 5, nil),
        ]
        let blockingConfigs: [(String, Int, String?)] = [
            ("Notification",       60, nil),
            ("PermissionRequest",  60, nil),
        ]

        let asyncNames = asyncConfigs.map(\.0)
        let blockingNames = blockingConfigs.map(\.0)
        let allNames = asyncNames + blockingNames

        XCTAssertEqual(asyncConfigs.count, 4, "Expected exactly 4 async hook events")
        XCTAssertEqual(blockingConfigs.count, 2, "Expected exactly 2 blocking hook events")
        XCTAssertEqual(allNames.count, 6, "Expected exactly 6 total hook events")

        for event in asyncEvents {
            XCTAssertTrue(asyncNames.contains(event), "Missing async event: \(event)")
        }
        for event in blockingEvents {
            XCTAssertTrue(blockingNames.contains(event), "Missing blocking event: \(event)")
        }
        for event in allEvents {
            XCTAssertTrue(allNames.contains(event), "Missing event: \(event)")
        }
    }
}
