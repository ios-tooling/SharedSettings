//
//  TypeSpecificTests.swift
//  SharedSettingsTests
//
//  Tests all supported types
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("Type-Specific Tests")
struct TypeSpecificTests {

	func createTestDefaults() -> (UserDefaults, String) {
		let suiteName = "test.types.\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		return (defaults, suiteName)
	}

	// MARK: - Test Keys for Different Types

	struct StringKey: SettingsKey {
		static let defaultValue = ""
		typealias Payload = String
	}

	struct BoolKey: SettingsKey {
		static let defaultValue = false
		typealias Payload = Bool
	}

	struct IntKey: SettingsKey {
		static let defaultValue = 0
		typealias Payload = Int
	}

	struct DoubleKey: SettingsKey {
		static let defaultValue = 0.0
		typealias Payload = Double
	}

	struct URLKey: SettingsKey {
		static let defaultValue = URL(string: "https://example.com")!
		typealias Payload = URL
	}

	struct DataKey: SettingsKey {
		static let defaultValue = Data()
		typealias Payload = Data
	}

	struct DateKey: SettingsKey {
		static let defaultValue = Date(timeIntervalSince1970: 0)
		typealias Payload = Date
	}

	struct StringArrayKey: SettingsKey {
		static let defaultValue: [String] = []
		typealias Payload = [String]
	}

	// MARK: - String Tests

	@Test("String value")
	func stringValue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = "Hello, World!"
		StringKey.set(value, in: testDefaults)
		#expect(StringKey.from(userDefaults: testDefaults) == value)
	}

	@Test("Empty string")
	func stringEmpty() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		StringKey.set("", in: testDefaults)
		#expect(StringKey.from(userDefaults: testDefaults) == "")
	}

	@Test("Unicode string")
	func stringUnicode() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = "Hello 👋 World 🌍 中文 العربية"
		StringKey.set(value, in: testDefaults)
		#expect(StringKey.from(userDefaults: testDefaults) == value)
	}

	// MARK: - Bool Tests

	@Test("Bool true")
	func boolTrue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		BoolKey.set(true, in: testDefaults)
		#expect(BoolKey.from(userDefaults: testDefaults) == true)
	}

	@Test("Bool false")
	func boolFalse() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		BoolKey.set(false, in: testDefaults)
		#expect(BoolKey.from(userDefaults: testDefaults) == false)
	}

	@Test("Missing bool key returns nil")
	func boolMissingKey() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = BoolKey.from(userDefaults: testDefaults)
		#expect(value == nil, "Missing bool key should return nil")
	}

	@Test("Bool toggle")
	func boolToggle() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		BoolKey.set(true, in: testDefaults)
		BoolKey.set(false, in: testDefaults)
		#expect(BoolKey.from(userDefaults: testDefaults) == false)
	}

	// MARK: - Int Tests

	@Test("Int positive")
	func intPositive() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		IntKey.set(42, in: testDefaults)
		#expect(IntKey.from(userDefaults: testDefaults) == 42)
	}

	@Test("Int negative")
	func intNegative() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		IntKey.set(-100, in: testDefaults)
		#expect(IntKey.from(userDefaults: testDefaults) == -100)
	}

	@Test("Int zero")
	func intZero() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		IntKey.set(0, in: testDefaults)
		#expect(IntKey.from(userDefaults: testDefaults) == 0)
	}

	@Test("Missing int key returns nil")
	func intMissingKey() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = IntKey.from(userDefaults: testDefaults)
		#expect(value == nil, "Missing int key should return nil")
	}

	@Test("Int max and min values")
	func intMaxMin() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		IntKey.set(Int.max, in: testDefaults)
		#expect(IntKey.from(userDefaults: testDefaults) == Int.max)

		IntKey.set(Int.min, in: testDefaults)
		#expect(IntKey.from(userDefaults: testDefaults) == Int.min)
	}

	// MARK: - Double Tests

	@Test("Double value")
	func doubleValue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = 3.14159
		DoubleKey.set(value, in: testDefaults)
		#expect(DoubleKey.from(userDefaults: testDefaults) == value)
	}

	@Test("Double zero")
	func doubleZero() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		DoubleKey.set(0.0, in: testDefaults)
		#expect(DoubleKey.from(userDefaults: testDefaults) == 0.0)
	}

	@Test("Missing double key returns nil")
	func doubleMissingKey() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let value = DoubleKey.from(userDefaults: testDefaults)
		#expect(value == nil, "Missing double key should return nil")
	}

	@Test("Double negative")
	func doubleNegative() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		DoubleKey.set(-123.456, in: testDefaults)
		#expect(DoubleKey.from(userDefaults: testDefaults) == -123.456)
	}

	// MARK: - URL Tests

	@Test("URL value")
	func urlValue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let url = URL(string: "https://apple.com")!
		URLKey.set(url, in: testDefaults)
		#expect(URLKey.from(userDefaults: testDefaults) == url)
	}

	@Test("File URL")
	func urlFile() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let url = URL(fileURLWithPath: "/tmp/test.txt")
		URLKey.set(url, in: testDefaults)
		#expect(URLKey.from(userDefaults: testDefaults) == url)
	}

	// MARK: - Data Tests

	@Test("Data value")
	func dataValue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let data = "test data".data(using: .utf8)!
		DataKey.set(data, in: testDefaults)
		#expect(DataKey.from(userDefaults: testDefaults) == data)
	}

	@Test("Empty data")
	func dataEmpty() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let data = Data()
		DataKey.set(data, in: testDefaults)
		#expect(DataKey.from(userDefaults: testDefaults) == data)
	}

	// MARK: - Date Tests

	@Test("Date value")
	func dateValue() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let date = Date()
		DateKey.set(date, in: testDefaults)
		let retrieved = DateKey.from(userDefaults: testDefaults)

		#expect(retrieved != nil)
		#expect(abs(retrieved!.timeIntervalSince1970 - date.timeIntervalSince1970) < 0.001)
	}

	@Test("Date distant past")
	func dateDistantPast() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let date = Date.distantPast
		DateKey.set(date, in: testDefaults)
		#expect(DateKey.from(userDefaults: testDefaults) == date)
	}

	@Test("Date distant future")
	func dateDistantFuture() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let date = Date.distantFuture
		DateKey.set(date, in: testDefaults)
		#expect(DateKey.from(userDefaults: testDefaults) == date)
	}

	// MARK: - String Array Tests

	@Test("String array")
	func stringArray() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let array = ["one", "two", "three"]
		StringArrayKey.set(array, in: testDefaults)
		#expect(StringArrayKey.from(userDefaults: testDefaults) == array)
	}

	@Test("Empty string array")
	func stringArrayEmpty() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let array: [String] = []
		StringArrayKey.set(array, in: testDefaults)
		#expect(StringArrayKey.from(userDefaults: testDefaults) == array)
	}

	@Test("String array with unicode")
	func stringArrayUnicode() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let array = ["Hello", "世界", "🌍"]
		StringArrayKey.set(array, in: testDefaults)
		#expect(StringArrayKey.from(userDefaults: testDefaults) == array)
	}

	// MARK: - RawRepresentable Tests

	@Test("String-backed enum")
	func stringEnum() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		enum Theme: String, Codable, Sendable {
			case light, dark, auto
		}

		struct ThemeKey: SettingsKey {
			static let defaultValue = Theme.light
			typealias Payload = Theme
		}

		ThemeKey.set(.dark, in: testDefaults)
		#expect(ThemeKey.from(userDefaults: testDefaults) == .dark)

		// Verify it's stored as string, not JSON
		let stored = testDefaults.string(forKey: ThemeKey.name)
		#expect(stored == "dark", "Should store as raw string")
	}

	@Test("Int-backed enum")
	func intEnum() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		enum Priority: Int, Codable, Sendable {
			case low = 1
			case medium = 2
			case high = 3
		}

		struct PriorityKey: SettingsKey {
			static let defaultValue = Priority.medium
			typealias Payload = Priority
		}

		PriorityKey.set(.high, in: testDefaults)
		#expect(PriorityKey.from(userDefaults: testDefaults) == .high)

		// Verify it's stored as int, not JSON
		let stored = testDefaults.integer(forKey: PriorityKey.name)
		#expect(stored == 3, "Should store as raw int")
	}

	// MARK: - Codable Tests

	@Test("Codable struct")
	func codableStruct() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct Person: Codable, Sendable, Equatable {
			let name: String
			let age: Int
		}

		struct PersonKey: SettingsKey {
			static let defaultValue = Person(name: "", age: 0)
			typealias Payload = Person
		}

		let person = Person(name: "Alice", age: 30)
		PersonKey.set(person, in: testDefaults)
		#expect(PersonKey.from(userDefaults: testDefaults) == person)
	}

	@Test("Codable array")
	func codableArray() {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct Item: Codable, Sendable, Equatable {
			let id: Int
			let name: String
		}

		struct ItemsKey: SettingsKey {
			static let defaultValue: [Item] = []
			typealias Payload = [Item]
		}

		let items = [
			Item(id: 1, name: "First"),
			Item(id: 2, name: "Second")
		]

		ItemsKey.set(items, in: testDefaults)
		#expect(ItemsKey.from(userDefaults: testDefaults) == items)
	}
}
