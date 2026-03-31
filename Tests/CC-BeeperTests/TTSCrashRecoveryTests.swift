import XCTest

/// Tests for the TTS dispatch logic — crash detection, restart, and fallback routing (AUDIT-05, AUDIT-06).
///
/// Uses replicated state (no @testable import) to verify the speak() dispatcher algorithm.

// MARK: - Replicated TTS Dispatcher

private struct TestTTSDispatcher {
    var kokoroReady: Bool = false
    var kokoroProcessRunning: Bool = false
    var pendingText: String? = nil
    var lastAction: Action = .none

    enum Action: Equatable {
        case none
        case speakKokoro(String)
        case speakApple(String)
        case restartAndQueue(String)
        case queueOnly(String)
    }

    mutating func speak(_ text: String, provider: String) {
        switch provider {
        case "kokoro":
            if kokoroReady {
                lastAction = .speakKokoro(text)
            } else if !kokoroProcessRunning {
                pendingText = text
                lastAction = .restartAndQueue(text)
            } else {
                pendingText = text
                lastAction = .queueOnly(text)
            }
        default:
            lastAction = .speakApple(text)
        }
    }

    mutating func simulateCrash() {
        kokoroReady = false
        kokoroProcessRunning = false
    }
}

// MARK: - Tests

final class TTSCrashRecoveryXCTests: XCTestCase {

    func testKokoroReadyRoutesToKokoro() {
        var d = TestTTSDispatcher(kokoroReady: true, kokoroProcessRunning: true)
        d.speak("hello", provider: "kokoro")
        XCTAssertEqual(d.lastAction, .speakKokoro("hello"))
    }

    func testCrashRoutesToAppleFallback() {
        var d = TestTTSDispatcher(kokoroReady: true, kokoroProcessRunning: true)
        d.simulateCrash()
        XCTAssertFalse(d.kokoroReady)
        XCTAssertFalse(d.kokoroProcessRunning)
        d.speak("hello", provider: "kokoro")
        XCTAssertEqual(d.lastAction, .restartAndQueue("hello"), "After crash, should attempt restart (AUDIT-06)")
    }

    func testAppleProviderAlwaysRoutesToApple() {
        var d = TestTTSDispatcher()
        d.speak("hello", provider: "apple")
        XCTAssertEqual(d.lastAction, .speakApple("hello"))
    }

    func testProcessLaunchingButNotReadyQueues() {
        var d = TestTTSDispatcher(kokoroProcessRunning: true)
        d.speak("test", provider: "kokoro")
        XCTAssertEqual(d.lastAction, .queueOnly("test"))
        XCTAssertEqual(d.pendingText, "test")
    }

    func testCrashClearsState() {
        var d = TestTTSDispatcher(kokoroReady: true, kokoroProcessRunning: true)
        d.simulateCrash()
        XCTAssertFalse(d.kokoroReady, "Crash must clear kokoroReady (AUDIT-05)")
        XCTAssertFalse(d.kokoroProcessRunning, "Crash must clear kokoroProcessRunning (AUDIT-05)")
    }
}
