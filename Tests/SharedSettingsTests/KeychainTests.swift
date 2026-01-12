//
//  KeychainTests.swift
//  SharedSettings
//
//  Created by Ben Gottlieb on 1/12/26.
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("Keychain Functionality")
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
	
	@Test("Fetch missing keychain setting")
	func fetchMissingKeychain() throws {
		struct TestSettingsKey: SettingsKey { static let defaultValue = "default"; static let location = SettingsLocation.keychain }
		defer { try? Keychain.delete(TestSettingsKey.name) }
		
		#expect(SharedSettings[TestSettingsKey.self] == nil)
	}
}
