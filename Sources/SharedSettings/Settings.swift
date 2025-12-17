//
//  Settings.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation
import os

extension UserDefaults: @retroactive @unchecked Sendable { }

nonisolated final class Settings: Sendable {
	public static nonisolated let instance = Settings()
	
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

	nonisolated subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload? {
		get {
			defaultsLock.withLock { userDefaults in
				if let userDefaults {
					return key.from(userDefaults: userDefaults)
				}
				return nil
			}
		}
		set {
			defaultsLock.withLock { userDefaults in
				if let userDefaults {
					key.set(newValue, in: userDefaults)
				}
			}
		}
	}
	
}
