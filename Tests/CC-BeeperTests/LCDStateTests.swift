import XCTest
import Foundation

/// Tests for the 8-state ClaudeState enum and its properties.
///
/// Note: @testable import is not supported for .executableTarget in this project.
/// These tests replicate the ClaudeState type locally to verify enum contract,
/// priority ordering, and computed property behavior (LCD-01, LCD-06, Pitfall 7).
/// The production types live in Sources/Monitor/ClaudeMonitor.swift.

// MARK: - Replicated ClaudeState for test verification

/// Mirror of production ClaudeState — must stay in sync with Sources/Monitor/ClaudeMonitor.swift
private enum TestClaudeState: Equatable {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput
    case listening
    case speaking

    var label: String {
        switch self {
        case .idle: "ZZZ..."
        case .working: "WORKING"
        case .done: "DONE!"
        case .error: "ERROR"
        case .approveQuestion: "APPROVE?"
        case .needsInput: "NEEDS INPUT"
        case .listening: "LISTENING"
        case .speaking: "SPEAKING"
        }
    }

    var priority: Int {
        switch self {
        case .error: return 7
        case .approveQuestion: return 6
        case .needsInput: return 5
        case .listening: return 4
        case .speaking: return 3
        case .working: return 2
        case .done: return 1
        case .idle: return 0
        }
    }

    var needsAttention: Bool { self == .approveQuestion || self == .needsInput }
    var canGoToConvo: Bool { self == .done }
}

// MARK: - LCDStateTests

struct LCDStateTests {

    // LCD-01: Verify 8 states exist with correct labels
    func testStateLabels() {
        XCTAssertEqual(TestClaudeState.idle.label, "ZZZ...")
        XCTAssertEqual(TestClaudeState.working.label, "WORKING")
        XCTAssertEqual(TestClaudeState.done.label, "DONE!")
        XCTAssertEqual(TestClaudeState.error.label, "ERROR")
        XCTAssertEqual(TestClaudeState.approveQuestion.label, "APPROVE?")
        XCTAssertEqual(TestClaudeState.needsInput.label, "NEEDS INPUT")
        XCTAssertEqual(TestClaudeState.listening.label, "LISTENING")
        XCTAssertEqual(TestClaudeState.speaking.label, "SPEAKING")
    }

    // LCD-06: Priority ordering (8-state)
    func testPriorityOrder() {
        XCTAssertEqual(TestClaudeState.error.priority, 7)
        XCTAssertEqual(TestClaudeState.approveQuestion.priority, 6)
        XCTAssertEqual(TestClaudeState.needsInput.priority, 5)
        XCTAssertEqual(TestClaudeState.listening.priority, 4)
        XCTAssertEqual(TestClaudeState.speaking.priority, 3)
        XCTAssertEqual(TestClaudeState.working.priority, 2)
        XCTAssertEqual(TestClaudeState.done.priority, 1)
        XCTAssertEqual(TestClaudeState.idle.priority, 0)
    }

    // LCD-06: Higher priority states are never overwritten by lower (8-state chain)
    func testPriorityEnforcement() {
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.approveQuestion.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.needsInput.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.working.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.done.priority)
        XCTAssertGreaterThan(TestClaudeState.error.priority, TestClaudeState.idle.priority)
        XCTAssertGreaterThan(TestClaudeState.approveQuestion.priority, TestClaudeState.needsInput.priority)
        XCTAssertGreaterThan(TestClaudeState.approveQuestion.priority, TestClaudeState.working.priority)
        XCTAssertGreaterThan(TestClaudeState.needsInput.priority, TestClaudeState.listening.priority)
        XCTAssertGreaterThan(TestClaudeState.listening.priority, TestClaudeState.speaking.priority)
        XCTAssertGreaterThan(TestClaudeState.speaking.priority, TestClaudeState.working.priority)
        XCTAssertGreaterThan(TestClaudeState.working.priority, TestClaudeState.done.priority)
        XCTAssertGreaterThan(TestClaudeState.done.priority, TestClaudeState.idle.priority)
    }

    // AUDIT-02: Multi-session priority resolution — highest priority wins
    func testMultiSessionPriorityResolution() {
        let sessionStates: [String: TestClaudeState] = [
            "session-1": .working,
            "session-2": .done,
            "session-3": .error,
        ]
        let highest = Array(sessionStates.values).max(by: { $0.priority < $1.priority }) ?? .idle
        XCTAssertEqual(highest, .error, "Error (priority 7) must win over working (2) and done (1)")

        let sessionStates2: [String: TestClaudeState] = [
            "a": .working,
            "b": .approveQuestion,
        ]
        let highest2 = Array(sessionStates2.values).max(by: { $0.priority < $1.priority }) ?? .idle
        XCTAssertEqual(highest2, .approveQuestion, "ApproveQuestion (6) must win over working (2)")
    }

    // Pitfall 7: needsAttention covers both attention states
    func testNeedsAttention() {
        XCTAssertTrue(TestClaudeState.approveQuestion.needsAttention)
        XCTAssertTrue(TestClaudeState.needsInput.needsAttention)
        XCTAssertFalse(TestClaudeState.working.needsAttention)
        XCTAssertFalse(TestClaudeState.done.needsAttention)
        XCTAssertFalse(TestClaudeState.idle.needsAttention)
        XCTAssertFalse(TestClaudeState.error.needsAttention)
        XCTAssertFalse(TestClaudeState.listening.needsAttention)
        XCTAssertFalse(TestClaudeState.speaking.needsAttention)
    }

    // Pitfall 7: canGoToConvo for done
    func testCanGoToConvo() {
        XCTAssertTrue(TestClaudeState.done.canGoToConvo)
        XCTAssertFalse(TestClaudeState.working.canGoToConvo)
        XCTAssertFalse(TestClaudeState.idle.canGoToConvo)
        XCTAssertFalse(TestClaudeState.approveQuestion.canGoToConvo)
        XCTAssertFalse(TestClaudeState.needsInput.canGoToConvo)
        XCTAssertFalse(TestClaudeState.error.canGoToConvo)
        XCTAssertFalse(TestClaudeState.listening.canGoToConvo)
        XCTAssertFalse(TestClaudeState.speaking.canGoToConvo)
    }
}

// MARK: - XCTest Wrapper

final class LCDStateXCTests: XCTestCase {
    private let suite = LCDStateTests()

    func testStateLabels() { suite.testStateLabels() }
    func testPriorityOrder() { suite.testPriorityOrder() }
    func testPriorityEnforcement() { suite.testPriorityEnforcement() }
    func testMultiSessionPriorityResolution() { suite.testMultiSessionPriorityResolution() }
    func testNeedsAttention() { suite.testNeedsAttention() }
    func testCanGoToConvo() { suite.testCanGoToConvo() }
}
