//
//  KeychainTests.swift
//  SharedSettings
//
//  Created by Ben Gottlieb on 1/12/26.
//

import Testing
import Foundation
@testable import SharedSettings

// Keychain is a process-global system store and these tests share a key name,
// so they must not run in parallel.
@Suite("Keychain Functionality", .serialized)
struct KeychainTestsTests {
	@Test("delete non-existent key")
	func deleteNonExistentKey() throws {
		let key = UUID().uuidString
		try Keychain.delete(key)
	}
	
	@Test("Set and fetch keychain setting")
	func setAndFetchKeychain() throws {
		struct TestSettingsKey: SettingsKey { static let defaultValue = "default"; static let location = SettingsLocation.keychain }
		defer { try? Keychain.delete(TestSettingsKey.name) }
		let testValue = "Test Value"
		
		SharedSettings[TestSettingsKey.self] = testValue
		#expect(SharedSettings[TestSettingsKey.self] == testValue)
	}
	
	@Test("In-memory keychain round-trips, deletes, and starts empty")
	func inMemoryKeychain() throws {
		struct TestSettingsKey: SettingsKey { static let defaultValue = "default"; static let location = SettingsLocation.keychain }
		SharedSettings.useInMemoryKeychain()
		defer { SharedSettings.useSystemKeychain() }

		SharedSettings[TestSettingsKey.self] = "in memory"
		#expect(SharedSettings[TestSettingsKey.self] == "in memory")
		try Keychain.delete(TestSettingsKey.name)
		#expect(SharedSettings[TestSettingsKey.self] == TestSettingsKey.defaultValue)

		SharedSettings[TestSettingsKey.self] = "dropped"
		SharedSettings.useInMemoryKeychain()
		#expect(SharedSettings[TestSettingsKey.self] == TestSettingsKey.defaultValue, "switching on again starts empty")
	}

	@Test("Fetch missing keychain setting")
	func fetchMissingKeychain() throws {
		struct TestSettingsKey: SettingsKey { static let defaultValue = "default"; static let location = SettingsLocation.keychain }
		defer { try? Keychain.delete(TestSettingsKey.name) }

		#expect(SharedSettings[TestSettingsKey.self] == TestSettingsKey.defaultValue)
	}
}
