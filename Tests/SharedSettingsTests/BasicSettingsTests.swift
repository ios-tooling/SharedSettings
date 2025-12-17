//
//  BasicSettingsTests.swift
//  SharedSettingsTests
//
//  Tests basic functionality of the Settings framework
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("Basic Settings Functionality")
struct BasicSettingsTests {

	// MARK: - Test Keys

	struct StringSetting: SettingsKey {
		static let defaultValue = "default"
		typealias Payload = String
	}

	struct IntSetting: SettingsKey {
		static let defaultValue = 42
		typealias Payload = Int
	}

	struct BoolSetting: SettingsKey {
		static let defaultValue = false
		typealias Payload = Bool
	}

	// MARK: - Helper

	func createTestDefaults() -> (UserDefaults, String) {
		let suiteName = "test.basic.\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		return (defaults, suiteName)
	}

	// MARK: - Tests

	@Test("Default value returns nil for non-existent key")
	func defaultValue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = StringSetting.from(userDefaults: testDefaults)

		#expect(value == nil, "Non-existent key should return nil")
	}

	@Test("Write and read value")
	func writeAndRead() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let testValue = "test value"

		StringSetting.set(testValue, in: testDefaults)
		let retrieved = StringSetting.from(userDefaults: testDefaults)

		#expect(retrieved == testValue)
	}

	@Test("Overwrite existing value")
	func overwrite() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		StringSetting.set("first", in: testDefaults)
		StringSetting.set("second", in: testDefaults)
		let retrieved = StringSetting.from(userDefaults: testDefaults)

		#expect(retrieved == "second")
	}

	@Test("Setting nil removes the key")
	func setNil() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		StringSetting.set("exists", in: testDefaults)
		#expect(StringSetting.from(userDefaults: testDefaults) != nil)

		StringSetting.set(nil, in: testDefaults)

		#expect(StringSetting.from(userDefaults: testDefaults) == nil)
	}

	@Test("Settings instance subscript")
	func settingsInstance() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)

		settings[StringSetting.self] = "subscript test"
		let retrieved = settings[StringSetting.self]

		#expect(retrieved == "subscript test")
	}

	@Test("Custom key name")
	func customKeyName() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct CustomNameSetting: SettingsKey {
			static let defaultValue = 0
			static let name = "custom.key.name"
			typealias Payload = Int
		}

		CustomNameSetting.set(123, in: testDefaults)

		let directValue = testDefaults.integer(forKey: "custom.key.name")
		#expect(directValue == 123)

		let retrieved = CustomNameSetting.from(userDefaults: testDefaults)
		#expect(retrieved == 123)
	}

	@Test("Persistence across instances")
	func persistenceAcrossInstances() {
		let suiteName = "test.persistence.\(UUID().uuidString)"
		let defaults1 = UserDefaults(suiteName: suiteName)!

		StringSetting.set("persistent", in: defaults1)

		let defaults2 = UserDefaults(suiteName: suiteName)!
		let retrieved = StringSetting.from(userDefaults: defaults2)

		#expect(retrieved == "persistent")

		defaults1.removePersistentDomain(forName: suiteName)
	}

	@Test("Multiple keys are independent")
	func multipleKeysIndependent() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)

		settings[StringSetting.self] = "string"
		settings[IntSetting.self] = 999
		settings[BoolSetting.self] = true

		#expect(settings[StringSetting.self] == "string")
		#expect(settings[IntSetting.self] == 999)
		#expect(settings[BoolSetting.self] == true)
	}
}
