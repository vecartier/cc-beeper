import XCTest
import Foundation
import Security

/// Tests for KeychainService — Keychain CRUD wrapper for API keys.
/// Note: @testable import is not supported for .executableTarget.
/// This test file embeds a local copy of the KeychainService logic for testing.
final class KeychainServiceTests: XCTestCase {

    // MARK: - Local stub matching KeychainService implementation

    private enum TestableKeychainService {
        private static let service = "com.claumagotchi.apikeys"

        static func save(_ value: String, account: String) {
            guard !value.isEmpty else { delete(account: account); return }
            guard let data = value.data(using: .utf8) else { return }
            let base: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrSynchronizable as String: false
            ]
            var add = base
            add[kSecValueData as String] = data
            let status = SecItemAdd(add as CFDictionary, nil)
            if status == errSecDuplicateItem {
                let attrs: [String: Any] = [kSecValueData as String: data]
                SecItemUpdate(base as CFDictionary, attrs as CFDictionary)
            }
        }

        static func load(account: String) -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecAttrSynchronizable as String: false
            ]
            var result: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
                  let data = result as? Data,
                  let value = String(data: data, encoding: .utf8),
                  !value.isEmpty else { return nil }
            return value
        }

        static func delete(account: String) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    // MARK: - Test account names (isolated from real keys)

    private let testGroqAccount = "test-groq-keychain-tests"
    private let testOpenAIAccount = "test-openai-keychain-tests"

    // MARK: - Setup / Teardown

    override func tearDown() {
        super.tearDown()
        TestableKeychainService.delete(account: testGroqAccount)
        TestableKeychainService.delete(account: testOpenAIAccount)
    }

    // MARK: - Tests

    /// Save a key then load it — returns the same value.
    func testKeychainSaveAndLoad() {
        TestableKeychainService.save("test-key-123", account: testGroqAccount)
        let loaded = TestableKeychainService.load(account: testGroqAccount)
        XCTAssertEqual(loaded, "test-key-123", "Loaded value should match saved value")
    }

    /// Save then save empty string — load returns nil (empty string deletes the entry).
    func testKeychainEmptyDeletesBehavior() {
        TestableKeychainService.save("abc", account: testGroqAccount)
        TestableKeychainService.save("", account: testGroqAccount)
        let loaded = TestableKeychainService.load(account: testGroqAccount)
        XCTAssertNil(loaded, "Saving empty string should delete the Keychain entry; load should return nil")
    }

    /// Save v1 then save v2 — load returns v2 (upsert, no duplicate item crash).
    func testKeychainUpsert() {
        TestableKeychainService.save("v1", account: testGroqAccount)
        TestableKeychainService.save("v2", account: testGroqAccount)
        let loaded = TestableKeychainService.load(account: testGroqAccount)
        XCTAssertEqual(loaded, "v2", "Second save should overwrite (upsert); loaded value should be v2")
    }

    /// Delete a non-existent account should not crash.
    func testKeychainDeleteNonexistent() {
        // Should complete without throwing or crashing
        TestableKeychainService.delete(account: "non-existent-account-xyzzy")
        XCTAssertTrue(true, "Deleting a non-existent Keychain account should not crash")
    }

    /// Load from an empty Keychain returns nil.
    func testKeychainLoadMissing() {
        TestableKeychainService.delete(account: testGroqAccount)
        let loaded = TestableKeychainService.load(account: testGroqAccount)
        XCTAssertNil(loaded, "Loading a missing Keychain entry should return nil")
    }

    /// Two accounts are independent (groq and openai don't share values).
    func testKeychainAccountIsolation() {
        TestableKeychainService.save("groq-key", account: testGroqAccount)
        TestableKeychainService.save("openai-key", account: testOpenAIAccount)

        XCTAssertEqual(TestableKeychainService.load(account: testGroqAccount), "groq-key")
        XCTAssertEqual(TestableKeychainService.load(account: testOpenAIAccount), "openai-key")
    }
}
