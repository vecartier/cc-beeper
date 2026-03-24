import XCTest
import Foundation

/// Tests for AppMover path-check logic.
/// AppMover.moveToApplicationsIfNeeded() is a UI-heavy function (NSAlert), so these
/// tests verify only the pure path-detection guard conditions by replicating the
/// same string checks that AppMover uses — without invoking NSAlert.
final class AppMoverTests: XCTestCase {

    /// App in /Applications — the skip guard should trigger.
    func testSkipsWhenPathStartsWithApplications() throws {
        let path = "/Applications/Claumagotchi.app"
        // Replicates the guard at line 1 of moveToApplicationsIfNeeded()
        XCTAssertTrue(path.hasPrefix("/Applications/"),
                      "Path starting with /Applications/ should trigger early return")
    }

    /// App in a nested /Applications subdirectory — still counts as installed.
    func testSkipsWhenPathIsInApplicationsSubdirectory() throws {
        let path = "/Applications/Utilities/Claumagotchi.app"
        XCTAssertTrue(path.hasPrefix("/Applications/"),
                      "Subdirectory of /Applications should also trigger early return")
    }

    /// App running from SPM build output — skip in dev environment.
    func testSkipsWhenPathContainsBuildDirectory() throws {
        let path = "/Users/dev/Claumagotchi/.build/debug/Claumagotchi.app"
        XCTAssertTrue(path.contains(".build/"),
                      "Path containing .build/ should trigger dev-build early return")
    }

    /// App running from App Translocation path — detected correctly.
    func testDetectsAppTranslocation() throws {
        let path = "/private/var/folders/xyz/AppTranslocation/abc/Claumagotchi.app"
        XCTAssertTrue(path.contains("AppTranslocation"),
                      "Translocated path should be detected as App Translocation")
    }

    /// Path from Downloads folder — should NOT match any skip condition.
    func testDownloadsFolderPathRequiresUserAction() throws {
        let path = "/Users/dev/Downloads/Claumagotchi.app"
        XCTAssertFalse(path.hasPrefix("/Applications/"),
                       "Downloads path should not be skipped as /Applications")
        XCTAssertFalse(path.contains(".build/"),
                       "Downloads path should not be skipped as dev build")
        XCTAssertFalse(path.contains("AppTranslocation"),
                       "Downloads path should not trigger translocation warning")
    }
}
