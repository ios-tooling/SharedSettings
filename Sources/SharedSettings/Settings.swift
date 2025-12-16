//
//  Settings.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation

nonisolated final class Settings: @unchecked Sendable {
	public static nonisolated let instance = Settings()
	
	var userDefaults: UserDefaults? = UserDefaults.standard
	
	@MainActor public func set(userDefaults: UserDefaults) {
		self.userDefaults = userDefaults
	}
	
	nonisolated subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload? {
		get {
			if let userDefaults {
				return key.from(userDefaults: userDefaults)
			}
			
			return nil
		}
		set {
			if let userDefaults {
				return key.set(newValue, in: userDefaults)
			}
		}
	}
	
}
