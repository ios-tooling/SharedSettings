//
//  CloudSettingsCacheTests.swift
//  SharedSettingsTests
//
//  Tests the in-process cache in front of the iCloud key-value store
//

import Testing
import Foundation
import os
@testable import SharedSettings

@Suite("CloudSettings Cache Tests")
struct CloudSettingsCacheTests {
	struct CloudStringKey: SettingsKey {
		static let defaultValue = "fallback"
		static let name = "test.cloud.cache.string.\(UUID().uuidString)"
		static var location: SettingsLocation { .cloudKit }
	}

	struct CloudBoolKey: SettingsKey {
		static let defaultValue = true
		static let name = "test.cloud.cache.bool.\(UUID().uuidString)"
		static var location: SettingsLocation { .cloudKit }
	}

	@Test("Repeated reads hit the store once, for a value and for an absent key")
	func repeatedReadsLoadOnce() {
		let cache = CloudSettingsCache()
		var valueLoads = 0
		var absentLoads = 0
		for _ in 0..<100 {
			#expect(cache.value(forKey: "present", load: { valueLoads += 1; return 7 }) == 7)
			#expect(cache.value(forKey: "absent", load: { () -> Bool? in absentLoads += 1; return nil }) == nil)
		}
		#expect(valueLoads == 1)
		#expect(absentLoads == 1)
	}

	@Test("A write is read back without a store hit")
	func writeThenRead() {
		let cache = CloudSettingsCache()
		cache.store("written", forKey: "key")
		#expect(cache.value(forKey: "key", load: { () -> String? in Issue.record("store was read"); return nil }) == "written")
	}

	@Test("A write that lands during a miss's load is not replaced by the stale loaded value")
	func writeDuringLoadWins() {
		let cache = CloudSettingsCache()
		let read = cache.value(forKey: "key", load: { () -> String? in
			cache.store("newer", forKey: "key")
			return "stale"
		})
		#expect(read == "newer")
		#expect(cache.value(forKey: "key", load: { () -> String? in Issue.record("store was read"); return nil }) == "newer")

		let cleared = cache.value(forKey: "cleared", load: { () -> String? in
			cache.store(String?.none, forKey: "cleared")
			return "stale"
		})
		#expect(cleared == nil)
		#expect(cache.value(forKey: "cleared", load: { () -> String? in Issue.record("store was read"); return nil }) == nil)
	}

	@Test("Writing through a cloud key returns the written value, and nil clears it to the default")
	func keyWriteThenReadAndClear() {
		defer {
			NSUbiquitousKeyValueStore.default.removeObject(forKey: CloudStringKey.name)
			NSUbiquitousKeyValueStore.default.removeObject(forKey: CloudBoolKey.name)
		}

		CloudStringKey.setInCloudKit("hello")
		#expect(CloudStringKey.fromCloudKit() == "hello")
		#expect(SharedSettings[CloudStringKey.self] == "hello")
		CloudStringKey.setInCloudKit(nil)
		#expect(CloudStringKey.fromCloudKit() == nil)
		#expect(SharedSettings[CloudStringKey.self] == "fallback")

		#expect(CloudBoolKey.fromCloudKit() == nil)   // unwritten Bool reads absent, so the default applies
		#expect(SharedSettings[CloudBoolKey.self] == true)
		SharedSettings[CloudBoolKey.self] = false
		#expect(CloudBoolKey.fromCloudKit() == false)
		CloudBoolKey.setInCloudKit(nil)
		#expect(SharedSettings[CloudBoolKey.self] == true)
	}

	@Test("An external change drops the changed keys, or every key on a sync or account change")
	func externalChangeInvalidates() {
		let cache = CloudSettingsCache()
		var loads = 0
		func read(_ key: String) -> Int? { cache.value(forKey: key, load: { loads += 1; return loads }) }

		_ = read("a"); _ = read("b")
		cache.invalidate(externalChange: [NSUbiquitousKeyValueStoreChangedKeysKey: ["a"], NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreServerChange])
		#expect(read("a") == 3)
		#expect(read("b") == 2)

		cache.invalidate(externalChange: [NSUbiquitousKeyValueStoreChangedKeysKey: ["a"], NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreAccountChange])
		#expect(read("b") == 4)

		cache.invalidate(externalChange: [NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreServerChange])
		#expect(read("a") == 5)
	}

	@Test("The store's external-change notification invalidates the shared cache before observers hear of it")
	func observerInvalidatesSharedCache() {
		let key = "test.cloud.cache.observed.\(UUID().uuidString)"
		CloudSettingsObserver.start()
		CloudSettingsCache.shared.store("old", forKey: key)

		let reread = OSAllocatedUnfairLock<String?>(initialState: nil)
		let token = NotificationCenter.default.addObserver(forName: SharedSettings.didChangeExternallyNotification, object: nil, queue: nil) { note in
			guard note.sharedSettingsChangedKeys == [key] else { return }
			let value = CloudSettingsCache.shared.value(forKey: key, load: { "fresh" })
			reread.withLock { $0 = value }
		}
		defer { NotificationCenter.default.removeObserver(token) }

		NotificationCenter.default.post(
			name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
			object: NSUbiquitousKeyValueStore.default,
			userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: [key], NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreServerChange]
		)
		#expect(reread.withLock { $0 } == "fresh")
	}
}
