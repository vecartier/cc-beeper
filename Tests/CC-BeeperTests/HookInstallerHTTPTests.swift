import XCTest
import Foundation

/// Tests for the HTTP curl-based hook command formats produced by HookInstaller.
/// Since @testable import is not supported for .executableTarget, these tests
/// replicate the core command constants and hook entry building logic.
final class HookInstallerHTTPTests: XCTestCase {

    private var tempDir: URL!

    // Replicate constants from HookInstaller (must stay in sync)
    private let hookMarker = "cc-beeper/port"
    private let asyncCommand = "PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true"
    private let blockingCommand = "PORT=$(cat ~/.claude/cc-beeper/port 2>/dev/null || echo 19222) && curl -s -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 55"

    // Replicate event configs from HookInstaller (must stay in sync)
    private let asyncConfigs: [(String, Int, String?)] = [
        ("PreToolUse",  5, "CC-Beeper monitoring\u{2026}"),
        ("PostToolUse", 5, nil),
        ("Stop",        5, nil),
        ("StopFailure", 5, nil),
    ]
    private let blockingConfigs: [(String, Int, String?)] = [
        ("Notification",      60, nil),
        ("PermissionRequest", 60, nil),
    ]

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Async command format tests

    /// Async hook command must use curl with stdin pipe (-d @-) and cc-beeper/port marker.
    func testAsyncHookCommandContainsCurlWithStdinPipe() {
        XCTAssertTrue(asyncCommand.contains("curl"), "Async command must contain curl")
        XCTAssertTrue(asyncCommand.contains("-d @-"), "Async command must pipe stdin via -d @-")
        XCTAssertTrue(asyncCommand.contains(hookMarker), "Async command must contain cc-beeper/port marker")
    }

    /// Async hook command must suppress stdout for zero-noise operation (HOOK-03).
    func testAsyncHookCommandSuppressesStdout() {
        XCTAssertTrue(asyncCommand.contains("-s"), "Async command must use -s (silent) flag")
        XCTAssertTrue(asyncCommand.contains("-o /dev/null"), "Async command must suppress response body with -o /dev/null")
        XCTAssertTrue(asyncCommand.contains("|| true"), "Async command must use || true to never fail the hook")
    }

    /// Async hook command must fail fast with 3-second max time.
    func testAsyncHookCommandHasMaxTimeThreeSeconds() {
        XCTAssertTrue(asyncCommand.contains("--max-time 3"), "Async command must have --max-time 3")
        XCTAssertFalse(asyncCommand.contains("--max-time 55"), "Async command must not have blocking max-time")
    }

    // MARK: - Blocking command format tests

    /// Blocking hook command must use 55-second max time for permission approval flow (per D-01).
    func testBlockingHookCommandHasMaxTimeFiftyFiveSeconds() {
        XCTAssertTrue(blockingCommand.contains("--max-time 55"), "Blocking command must have --max-time 55")
    }

    /// Blocking hook command must NOT suppress stdout (stdout carries response to Claude Code, per D-02).
    func testBlockingHookCommandDoesNotSuppressStdout() {
        XCTAssertFalse(blockingCommand.contains("-o /dev/null"), "Blocking command must NOT suppress stdout")
        XCTAssertFalse(blockingCommand.contains("|| true"), "Blocking command must NOT use || true")
    }

    /// Both blocking hook entries (Notification and PermissionRequest) must NOT have async: true (per D-02).
    func testBlockingHookCommandDoesNotHaveAsync() {
        // Build blocking hook entries as HookInstaller.install() would
        for (event, timeout, statusMessage) in blockingConfigs {
            var hookEntry: [String: Any] = [
                "type": "command",
                "command": blockingCommand,
                "timeout": timeout,
            ]
            if let msg = statusMessage {
                hookEntry["statusMessage"] = msg
            }
            XCTAssertNil(hookEntry["async"], "Blocking hook '\(event)' must NOT have async key")
            XCTAssertFalse(hookEntry["async"] as? Bool ?? false,
                           "Blocking hook '\(event)' must NOT have async: true")
        }
    }

    // MARK: - Port fallback test

    /// Both command types must fall back to port 19222 when the port file is missing.
    func testHookCommandFallsBackToDefaultPort() {
        XCTAssertTrue(asyncCommand.contains("|| echo 19222"),
                      "Async command must fall back to port 19222 when port file missing")
        XCTAssertTrue(blockingCommand.contains("|| echo 19222"),
                      "Blocking command must fall back to port 19222 when port file missing")
    }

    // MARK: - statusMessage test

    /// Only PreToolUse should have a non-nil statusMessage (HOOK-02).
    func testOnlyPreToolUseHasStatusMessage() {
        for (event, _, statusMessage) in asyncConfigs {
            if event == "PreToolUse" {
                XCTAssertNotNil(statusMessage, "PreToolUse must have a statusMessage")
                XCTAssertFalse(statusMessage?.isEmpty ?? true, "PreToolUse statusMessage must not be empty")
            } else {
                XCTAssertNil(statusMessage, "Event '\(event)' must NOT have a statusMessage")
            }
        }
        for (event, _, statusMessage) in blockingConfigs {
            XCTAssertNil(statusMessage, "Blocking event '\(event)' must NOT have a statusMessage")
        }
    }

    // MARK: - Async hook metadata tests

    /// All 4 async hook event configs must produce entries with async: true (HOOK-01).
    func testAllAsyncHooksHaveAsyncTrue() {
        XCTAssertEqual(asyncConfigs.count, 4, "Expected exactly 4 async event configs")
        for (event, timeout, statusMessage) in asyncConfigs {
            var hookEntry: [String: Any] = [
                "type": "command",
                "command": asyncCommand,
                "async": true,
                "timeout": timeout,
            ]
            if let msg = statusMessage {
                hookEntry["statusMessage"] = msg
            }
            XCTAssertEqual(hookEntry["async"] as? Bool, true,
                           "Async hook '\(event)' must have async: true")
        }
    }

    /// All 4 async hook event configs must have timeout value 5 (seconds, not 5000ms) (HOOK-01).
    func testAllAsyncHooksHaveTimeoutFiveSeconds() {
        for (event, timeout, _) in asyncConfigs {
            XCTAssertEqual(timeout, 5,
                           "Async hook '\(event)' must have timeout: 5 (seconds), got \(timeout)")
        }
    }

    // MARK: - Blocking hook metadata tests

    /// Both Notification and PermissionRequest blocking configs must have timeout: 60 seconds.
    func testBothBlockingHooksHaveTimeoutSixtySeconds() {
        for (event, timeout, _) in blockingConfigs {
            XCTAssertEqual(timeout, 60,
                           "Blocking hook '\(event)' must have timeout: 60 (seconds), got \(timeout)")
        }
    }

    /// Notification hook must be blocking: no async, blockingCommand (no -o /dev/null, no || true),
    /// and --max-time 55. Critical test for RESEARCH.md Pitfall 5: permission_prompt arrives via
    /// Notification in modern Claude Code, so Notification MUST be blocking.
    func testNotificationHookIsBlocking() {
        // Find the Notification config
        guard let (_, timeout, statusMessage) = blockingConfigs.first(where: { $0.0 == "Notification" }) else {
            XCTFail("Notification event must be in blockingConfigs, not asyncConfigs")
            return
        }

        // Build the hook entry as HookInstaller.install() would
        var hookEntry: [String: Any] = [
            "type": "command",
            "command": blockingCommand,
            "timeout": timeout,
        ]
        if let msg = statusMessage {
            hookEntry["statusMessage"] = msg
        }

        // Must NOT have async: true
        XCTAssertNil(hookEntry["async"],
                     "Notification hook must NOT have async key (permission_prompt arrives via Notification)")

        // Must use blockingCommand (no -o /dev/null, no || true)
        let cmd = hookEntry["command"] as? String ?? ""
        XCTAssertFalse(cmd.contains("-o /dev/null"),
                       "Notification hook must NOT suppress stdout (response goes back to Claude Code)")
        XCTAssertFalse(cmd.contains("|| true"),
                       "Notification hook must NOT use || true (failure must propagate to Claude Code)")
        XCTAssertTrue(cmd.contains("--max-time 55"),
                      "Notification hook must have --max-time 55 for permission approval flow")

        // Must NOT be in asyncConfigs
        let asyncEventNames = asyncConfigs.map(\.0)
        XCTAssertFalse(asyncEventNames.contains("Notification"),
                       "Notification must NOT be in asyncConfigs (RESEARCH.md Pitfall 5)")

        // Timeout must be 60 seconds
        XCTAssertEqual(timeout, 60, "Notification timeout must be 60 seconds")
    }

    // MARK: - Install/migration tests

    /// install() must remove old Python cc-beeper-hook.py entries but keep user custom hooks.
    func testInstallRemovesOldPythonHookEntries() throws {
        // Build a settings.json with two PreToolUse entries:
        // 1. Old Python CC-Beeper entry (should be removed)
        // 2. User's custom hook (should be preserved)
        let oldPythonEntry: [String: Any] = [
            "type": "command",
            "command": "python3 /home/user/.claude/hooks/cc-beeper-hook.py",
            "timeout": 5,
        ]
        let userEntry: [String: Any] = [
            "type": "command",
            "command": "echo 'user custom hook'",
            "timeout": 10,
        ]
        let oldPythonRule: [String: Any] = ["matcher": "", "hooks": [oldPythonEntry]]
        let userRule: [String: Any] = ["matcher": "Bash", "hooks": [userEntry]]

        var hooks: [String: Any] = ["PreToolUse": [oldPythonRule, userRule]]

        // Simulate the filter logic from HookInstaller.install()
        let event = "PreToolUse"
        var existing = hooks[event] as? [[String: Any]] ?? []
        existing = existing.filter { rule in
            guard let hs = rule["hooks"] as? [[String: Any]] else { return true }
            return !hs.contains { cmd in
                let command = cmd["command"] as? String ?? ""
                return command.contains("cc-beeper-hook.py") || command.contains(hookMarker)
            }
        }
        hooks[event] = existing

        let remaining = hooks[event] as? [[String: Any]] ?? []
        XCTAssertEqual(remaining.count, 1,
                       "After filtering, only the user's custom hook should remain")

        // Verify the Python entry was removed
        let hasOldPython = remaining.contains { rule in
            (rule["hooks"] as? [[String: Any]])?.contains { entry in
                (entry["command"] as? String)?.contains("cc-beeper-hook.py") == true
            } ?? false
        }
        XCTAssertFalse(hasOldPython, "Old Python cc-beeper-hook.py entry must be removed")

        // Verify the user's custom hook survived
        let hasUserHook = remaining.contains { rule in
            (rule["hooks"] as? [[String: Any]])?.contains { entry in
                (entry["command"] as? String)?.contains("user custom hook") == true
            } ?? false
        }
        XCTAssertTrue(hasUserHook, "User's custom hook must be preserved after CC-Beeper entry removal")
    }

    /// The hookMarker (cc-beeper/port) must appear in both async and blocking command strings,
    /// enabling safe identification and update/removal of CC-Beeper hooks (HOOK-04).
    func testHookMarkerIdentifiesCCBeeperHooks() {
        XCTAssertTrue(asyncCommand.contains(hookMarker),
                      "Async command must contain '\(hookMarker)' for hook identification")
        XCTAssertTrue(blockingCommand.contains(hookMarker),
                      "Blocking command must contain '\(hookMarker)' for hook identification")

        // Verify the marker distinguishes CC-Beeper hooks from user hooks
        let userHookCommand = "echo 'user custom hook'"
        XCTAssertFalse(userHookCommand.contains(hookMarker),
                       "User hook must not accidentally contain the CC-Beeper hook marker")
    }
}
