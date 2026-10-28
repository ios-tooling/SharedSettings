//
//  CloudSettingsCache.swift
//  SharedSettings
//

import Foundation
import os

/// In-process memory over `NSUbiquitousKeyValueStore` reads. On iOS 27 every store read is a
/// synchronous XPC to the syncdefaults daemon, so a view that reads a `.cloudKit` setting per
/// cell can stall the main thread for seconds. Each key is read from the store once, then
/// served from here until a write replaces it or an external change drops it.
final class CloudSettingsCache: Sendable {
	static let shared = CloudSettingsCache()

	private enum Entry { case absent, value(any Sendable) }
	private let entries = OSAllocatedUnfairLock<[String: Entry]>(initialState: [:])

	/// The cached value for `key`, or the result of `load` (cached too, including nil) on a miss.
	/// `load` runs outside the lock, so a slow store read never blocks other keys.
	func value<Payload: Sendable>(forKey key: String, load: () -> Payload?) -> Payload? {
		switch entries.withLock({ $0[key] }) {
		case .absent: return nil
		case .value(let cached as Payload): return cached
		default:
			// A write that lands while `load` runs is newer than what was loaded, so it wins.
			let loaded = load()
			return entries.withLock { entries in
				switch entries[key] {
				case .absent: return nil
				case .value(let current as Payload): return current
				default:
					entries[key] = loaded.map { .value($0) } ?? .absent
					return loaded
				}
			}
		}
	}

	/// Records what was just written for `key`; nil records it as absent.
	func store<Payload: Sendable>(_ value: Payload?, forKey key: String) {
		entries.withLock { $0[key] = value.map { .value($0) } ?? .absent }
	}

	/// Forgets `keys` (every key when nil), so the next read goes back to the store.
	func invalidate(_ keys: [String]?) {
		entries.withLock { entries in
			guard let keys else { entries.removeAll(); return }
			for key in keys { entries[key] = nil }
		}
	}

	/// Applies an `NSUbiquitousKeyValueStore.didChangeExternallyNotification`'s user info: the
	/// changed keys are dropped, or everything when the list is missing or the change is an
	/// initial sync or an account change (either can replace any key).
	func invalidate(externalChange userInfo: [AnyHashable: Any]?) {
		let reason = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
		let keys = userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
		let replacesAll = reason == NSUbiquitousKeyValueStoreInitialSyncChange || reason == NSUbiquitousKeyValueStoreAccountChange
		invalidate(replacesAll ? nil : keys)
	}
}
