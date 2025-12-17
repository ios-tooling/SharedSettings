//
//  ThreadSafetyTests.swift
//  SharedSettingsTests
//
//  Tests thread safety and concurrent access
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("Thread Safety Tests")
struct ThreadSafetyTests {

	func createTestDefaults() -> (UserDefaults, String) {
		let suiteName = "test.thread.\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		return (defaults, suiteName)
	}

	// MARK: - Test Keys

	struct CounterKey: SettingsKey {
		static let defaultValue = 0
		typealias Payload = Int
	}

	struct StringKey: SettingsKey {
		static let defaultValue = ""
		typealias Payload = String
	}

	// MARK: - Tests

	@Test("Concurrent reads")
	func concurrentReads() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		settings[StringKey.self] = "test value"

		await withTaskGroup(of: Void.self) { group in
			for _ in 0..<1000 {
				group.addTask {
					let value = settings[StringKey.self]
					#expect(value == "test value")
				}
			}
		}
	}

	@Test("Concurrent writes")
	func concurrentWrites() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)

		await withTaskGroup(of: Void.self) { group in
			for i in 0..<1000 {
				group.addTask {
					settings[StringKey.self] = "value_\(i)"
				}
			}
		}

		let finalValue = settings[StringKey.self]
		#expect(finalValue != nil)
		#expect(finalValue!.starts(with: "value_"))
	}

	@Test("Concurrent read and write")
	func concurrentReadAndWrite() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		settings[CounterKey.self] = 0

		await withTaskGroup(of: Void.self) { group in
			// Writers
			for i in 0..<500 where i % 2 == 0 {
				group.addTask {
					settings[CounterKey.self] = i
				}
			}

			// Readers
			for _ in 0..<500 {
				group.addTask {
					_ = settings[CounterKey.self]
				}
			}
		}
	}

	@Test("Concurrent UserDefaults swapping")
	func concurrentUserDefaultsSwapping() async {
		let suite1 = "test.swap1.\(UUID().uuidString)"
		let suite2 = "test.swap2.\(UUID().uuidString)"
		let defaults1 = UserDefaults(suiteName: suite1)!
		let defaults2 = UserDefaults(suiteName: suite2)!
		defer {
			defaults1.removePersistentDomain(forName: suite1)
			defaults2.removePersistentDomain(forName: suite2)
		}

		let settings = Settings(defaults: defaults1)
		settings[StringKey.self] = "defaults1"
		StringKey.set("defaults2", in: defaults2)

		await withTaskGroup(of: Void.self) { group in
			// Swap UserDefaults
			for i in 0..<100 {
				group.addTask {
					if i % 2 == 0 {
						settings.set(userDefaults: defaults1)
					} else {
						settings.set(userDefaults: defaults2)
					}
				}
			}

			// Read while swapping
			for _ in 0..<100 {
				group.addTask {
					_ = settings[StringKey.self]
				}
			}
		}
	}

	@Test("Settings subscript thread safety")
	func settingsSubscriptThreadSafety() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)

		await withTaskGroup(of: Void.self) { group in
			for i in 0..<1000 {
				group.addTask {
					if i % 2 == 0 {
						settings[CounterKey.self] = i
					} else {
						_ = settings[CounterKey.self]
					}
				}
			}
		}
	}

	@Test("Stress test across multiple keys")
	func stressTest() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		struct Key1: SettingsKey {
			static let defaultValue = ""
			typealias Payload = String
		}
		struct Key2: SettingsKey {
			static let defaultValue = 0
			typealias Payload = Int
		}
		struct Key3: SettingsKey {
			static let defaultValue = false
			typealias Payload = Bool
		}

		let settings = Settings(defaults: testDefaults)

		await withTaskGroup(of: Void.self) { group in
			for i in 0..<2000 {
				group.addTask {
					switch i % 6 {
					case 0:
						settings[Key1.self] = "string_\(i)"
					case 1:
						_ = settings[Key1.self]
					case 2:
						settings[Key2.self] = i
					case 3:
						_ = settings[Key2.self]
					case 4:
						settings[Key3.self] = (i % 2 == 0)
					case 5:
						_ = settings[Key3.self]
					default:
						break
					}
				}
			}
		}
	}

	@Test("Data race detection")
	func dataRaceDetection() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)

		// Run with Thread Sanitizer: swift test -Xswiftc -sanitize=thread
		await withTaskGroup(of: Void.self) { group in
			for i in 0..<500 {
				group.addTask {
					settings[CounterKey.self] = i
				}
				group.addTask {
					_ = settings[CounterKey.self]
				}
			}
		}
	}
}
