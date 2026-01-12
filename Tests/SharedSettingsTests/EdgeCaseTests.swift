//
//  EdgeCaseTests.swift
//  SharedSettingsTests
//
//  Tests edge cases and error conditions
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("Edge Case Tests")
struct EdgeCaseTests {

	func createTestDefaults() -> (UserDefaults, String) {
		let suiteName = "test.edge.\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		return (defaults, suiteName)
	}

	// MARK: - Test Keys

	struct StringKey: SettingsKey {
		static let defaultValue = "default"
		typealias Payload = String
	}

	struct CodableKey: SettingsKey {
		static let defaultValue = TestStruct(value: 0)
		typealias Payload = TestStruct
	}

	struct TestStruct: Codable, Sendable, Equatable {
		let value: Int
	}

	// MARK: - Tests

	@Test("Reading non-existent key returns nil")
	func readingNonExistentKey() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = StringKey.from(userDefaults: testDefaults)
		#expect(value == nil)
	}

	@Test("Setting nil removes key")
	func settingNilRemovesKey() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		StringKey.set("exists", in: testDefaults)
		#expect(testDefaults.object(forKey: StringKey.name) != nil)

		StringKey.set(nil, in: testDefaults)

		#expect(testDefaults.object(forKey: StringKey.name) == nil)
		#expect(StringKey.from(userDefaults: testDefaults) == nil)
	}

	@Test("Corrupted Codable data returns nil")
	func corruptedCodableData() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let corruptData = "not valid json".data(using: .utf8)!
		testDefaults.set(corruptData, forKey: CodableKey.name)

		let value = CodableKey.from(userDefaults: testDefaults)
		#expect(value == nil, "Should handle corrupt data gracefully")
	}

	@Test("Wrong type data returns nil")
	func wrongTypeData() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		testDefaults.set("wrong type", forKey: CodableKey.name)

		let value = CodableKey.from(userDefaults: testDefaults)
		#expect(value == nil)
	}

	@Test("Empty data returns nil")
	func emptyData() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		testDefaults.set(Data(), forKey: CodableKey.name)

		let value = CodableKey.from(userDefaults: testDefaults)
		#expect(value == nil)
	}

	@Test("Setting nil removes Codable value")
	func encodingFailureDoesNotDeleteExisting() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let original = TestStruct(value: 42)
		CodableKey.set(original, in: testDefaults)
		#expect(CodableKey.from(userDefaults: testDefaults) == original)

		CodableKey.set(nil, in: testDefaults)

		#expect(CodableKey.from(userDefaults: testDefaults) == nil)
	}

	@Test("Empty string preserves")
	func emptyString() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		StringKey.set("", in: testDefaults)
		#expect(StringKey.from(userDefaults: testDefaults) == "")
	}

	@Test("Whitespace string preserves")
	func whitespaceString() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		StringKey.set("   ", in: testDefaults)
		#expect(StringKey.from(userDefaults: testDefaults) == "   ")
	}

	@Test("Very long string (1MB)")
	func veryLongString() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let longString = String(repeating: "a", count: 1_000_000)

		StringKey.set(longString, in: testDefaults)
		let retrieved = StringKey.from(userDefaults: testDefaults)

		#expect(retrieved == longString)
	}

	@Test("Special characters in key name")
	func specialCharactersInKey() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct SpecialKey: SettingsKey {
			static let defaultValue = ""
			static let name = "key.with.dots/and\\slashes:and:colons"
			typealias Payload = String
		}

		SpecialKey.set("test", in: testDefaults)
		let retrieved = SpecialKey.from(userDefaults: testDefaults)

		#expect(retrieved == "test")
	}

	@Test("Multiple settings instances are same")
	func multipleSettingsInstances() {
		let instance1 = SharedSettings.instance
		let instance2 = SharedSettings.instance

		#expect(instance1 === instance2)
	}

	@Test("Bool distinguishes not-set from false")
	func boolDistinguishesNotSetFromFalse() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct BoolKey: SettingsKey {
			static let defaultValue = false
			typealias Payload = Bool
		}

		let notSet = BoolKey.from(userDefaults: testDefaults)
		#expect(notSet == nil, "Missing bool key should return nil")

		BoolKey.set(false, in: testDefaults)
		let setToFalse = BoolKey.from(userDefaults: testDefaults)

		#expect(setToFalse == false, "Explicitly set false should return false")
	}

	@Test("Int distinguishes not-set from zero")
	func intDistinguishesNotSetFromZero() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct IntKey: SettingsKey {
			static let defaultValue = 0
			typealias Payload = Int
		}

		let notSet = IntKey.from(userDefaults: testDefaults)
		#expect(notSet == nil, "Missing int key should return nil")

		IntKey.set(0, in: testDefaults)
		let setToZero = IntKey.from(userDefaults: testDefaults)

		#expect(setToZero == 0, "Explicitly set zero should return 0")
	}

	@Test("Double distinguishes not-set from zero")
	func doubleDistinguishesNotSetFromZero() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct DoubleKey: SettingsKey {
			static let defaultValue = 0.0
			typealias Payload = Double
		}

		let notSet = DoubleKey.from(userDefaults: testDefaults)
		#expect(notSet == nil, "Missing double key should return nil")

		DoubleKey.set(0.0, in: testDefaults)
		let setToZero = DoubleKey.from(userDefaults: testDefaults)

		#expect(setToZero == 0.0, "Explicitly set zero should return 0.0")
	}

	@Test("Invalid RawRepresentable raw value returns nil")
	func rawRepresentableInvalidRawValue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		enum Status: String, Codable, Sendable {
			case active, inactive
		}

		struct StatusKey: SettingsKey {
			static let defaultValue = Status.active
			typealias Payload = Status
		}

		testDefaults.set("invalid_status", forKey: StatusKey.name)

		let value = StatusKey.from(userDefaults: testDefaults)
		#expect(value == nil, "Invalid raw value should return nil")
	}
}
