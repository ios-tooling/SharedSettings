//
//  CloudKitTests.swift
//  SharedSettingsTests
//
//  Tests the iCloud key-value store readers and writers
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("CloudKit Tests")
struct CloudKitTests {
	struct TrueByDefaultKey: SettingsKey {
		static let defaultValue = true
		static let name = "test.cloud.bool.\(UUID().uuidString)"
		static var location: SettingsLocation { .cloudKit }
	}

	@Test("An unwritten cloud Bool reads its default, and clearing restores it")
	func unwrittenBoolReadsDefault() {
		defer { NSUbiquitousKeyValueStore.default.removeObject(forKey: TrueByDefaultKey.name) }

		#expect(TrueByDefaultKey.fromCloudKit() == nil)
		#expect((TrueByDefaultKey.fromCloudKit() ?? TrueByDefaultKey.defaultValue) == true)

		TrueByDefaultKey.setInCloudKit(false)
		// Without an iCloud entitlement (swift test on a Mac) the store drops writes; only the read half applies.
		guard NSUbiquitousKeyValueStore.default.object(forKey: TrueByDefaultKey.name) != nil else { return }
		#expect(TrueByDefaultKey.fromCloudKit() == false)

		TrueByDefaultKey.setInCloudKit(nil)
		#expect(TrueByDefaultKey.fromCloudKit() == nil)
		#expect((TrueByDefaultKey.fromCloudKit() ?? TrueByDefaultKey.defaultValue) == true)
	}
}
