import XCTest

/// Tests for voice injection safety guards — clipboard changeCount and frontmost app verification
/// (AUDIT-07, AUDIT-08). Uses replicated logic (no @testable import).

// MARK: - Replicated Guards

private struct TestClipboardGuard {
    static func shouldRestore(changeCountAfterWrite: Int, changeCountAfterPaste: Int) -> Bool {
        return changeCountAfterPaste == changeCountAfterWrite
    }
}

private struct TestInjectionGuard {
    static let terminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "io.alacritty",
        "net.kovidgoyal.kitty",
        "com.github.wez.wezterm",
    ]

    static let ideBundleIDs: Set<String> = [
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "dev.zed.Zed",
        "com.mitchellh.ghostty",
    ]

    static let allFocusable: Set<String> = terminalBundleIDs.union(ideBundleIDs)

    static func shouldInject(frontmostBundleID: String) -> Bool {
        return allFocusable.contains(frontmostBundleID)
    }
}

// MARK: - Tests

final class VoiceInjectionXCTests: XCTestCase {

    // MARK: - Clipboard changeCount (AUDIT-07)

    func testChangeCountGuard_NoExternalWrite_ShouldRestore() {
        XCTAssertTrue(
            TestClipboardGuard.shouldRestore(changeCountAfterWrite: 5, changeCountAfterPaste: 5),
            "No external write — safe to restore clipboard"
        )
    }

    func testChangeCountGuard_ExternalWrite_ShouldNotRestore() {
        XCTAssertFalse(
            TestClipboardGuard.shouldRestore(changeCountAfterWrite: 5, changeCountAfterPaste: 7),
            "External write detected — must not clobber user's clipboard"
        )
    }

    func testChangeCountGuard_MultipleExternalWrites() {
        XCTAssertFalse(
            TestClipboardGuard.shouldRestore(changeCountAfterWrite: 5, changeCountAfterPaste: 10)
        )
    }

    // MARK: - Frontmost app verification (AUDIT-08)

    func testInjectionGuard_TerminalApp_ShouldInject() {
        XCTAssertTrue(TestInjectionGuard.shouldInject(frontmostBundleID: "com.apple.Terminal"))
        XCTAssertTrue(TestInjectionGuard.shouldInject(frontmostBundleID: "com.googlecode.iterm2"))
    }

    func testInjectionGuard_NonTerminalApp_ShouldAbort() {
        XCTAssertFalse(TestInjectionGuard.shouldInject(frontmostBundleID: "com.apple.Safari"))
        XCTAssertFalse(TestInjectionGuard.shouldInject(frontmostBundleID: "com.apple.Finder"))
        XCTAssertFalse(TestInjectionGuard.shouldInject(frontmostBundleID: ""))
    }

    func testInjectionGuard_AllKnownTerminals() {
        XCTAssertEqual(TestInjectionGuard.terminalBundleIDs.count, 6, "Must have exactly 6 known terminals")
        for bid in TestInjectionGuard.terminalBundleIDs {
            XCTAssertTrue(TestInjectionGuard.shouldInject(frontmostBundleID: bid),
                          "\(bid) must be recognized as focusable")
        }
    }

    func testInjectionGuard_IDEApps_ShouldInject() {
        XCTAssertTrue(TestInjectionGuard.shouldInject(frontmostBundleID: "com.microsoft.VSCode"))
        XCTAssertTrue(TestInjectionGuard.shouldInject(frontmostBundleID: "com.todesktop.230313mzl4w4u92"))
        XCTAssertTrue(TestInjectionGuard.shouldInject(frontmostBundleID: "dev.zed.Zed"))
        XCTAssertTrue(TestInjectionGuard.shouldInject(frontmostBundleID: "com.mitchellh.ghostty"))
    }

    func testInjectionGuard_EmptyBundleID_ShouldAbort() {
        XCTAssertFalse(
            TestInjectionGuard.shouldInject(frontmostBundleID: ""),
            "Empty bundle ID (nil frontmostApplication) must abort injection"
        )
    }
}
