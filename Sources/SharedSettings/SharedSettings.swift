//
//  SharedSettings.swift
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation
import os

extension UserDefaults: @retroactive @unchecked Sendable { }

nonisolated public final class SharedSettings: Sendable {
	// The iCloud key-value observer starts lazily on first `.cloudKit` access
	// (see `SettingsKey.cloudKitKeyValueStore`), so apps that never use a
	// cloud-backed key don't touch `NSUbiquitousKeyValueStore` — and therefore
	// don't need the ubiquity-kvstore entitlement or hit its missing-entitlement log.
	public static nonisolated let instance: SharedSettings = SharedSettings()

	internal init(defaults: UserDefaults) {
		defaultsLock = .init(initialState: defaults)
	}

	internal init() {
		defaultsLock = .init(initialState: .standard)
	}
	
	// UserDefaults is threadsafe, according to the documentation, so we're okay to use it in a nonisolated context
	private let defaultsLock: OSAllocatedUnfairLock<UserDefaults?>

	public func set(userDefaults: UserDefaults) {
		defaultsLock.withLock { $0 = userDefaults }
	}
	
	public nonisolated static subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload {
		get { instance[key] }
		set { instance[key] = newValue }
	}

	nonisolated subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload  {
		get {
			switch key.location {
			case .userDefaults:
				return defaultsLock.withLock { userDefaults in
					if let userDefaults {
						return key.from(userDefaults: userDefaults) ?? key.defaultValue
					}
					return key.defaultValue
				}
				
			case .cloudKit:
				return key.fromCloudKit() ?? key.defaultValue
				
			case .keychain:
				return key.fromKeychain() ?? key.defaultValue
			}
		}
		set {
			set(newValue, forKey: key)
		}
	}
	
	func set<Key: SettingsKey>(_ value: Key.Payload?, forKey key: Key.Type) {
		switch key.location {
		case .userDefaults:
			defaultsLock.withLock { userDefaults in
				if let userDefaults {
					key.set(value, in: userDefaults)
				}
			}
			
		case .cloudKit:
			key.setInCloudKit(value)
			
		case .keychain:
			key.setInKeychain(value)
		}
	}
	
}
