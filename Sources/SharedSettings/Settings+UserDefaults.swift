//
//  Settings+UserDefaults.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/16/25.
//

import Foundation

extension SettingsKey where Payload == String {
	static func from(userDefaults: UserDefaults) -> Payload? {
		userDefaults.string(forKey: keyName)
	}
	
	static func set(_ value: Payload?, in userDefaults: UserDefaults) {
		userDefaults.set(value, forKey: keyName)
	}
}

extension SettingsKey where Payload == String? {
	static func from(userDefaults: UserDefaults) -> Payload? { userDefaults.string(forKey: keyName) }
	
	static func set(_ value: Payload?, in userDefaults: UserDefaults) {
		if let value {
			userDefaults.set(value, forKey: keyName)
		} else {
			userDefaults.removeObject(forKey: keyName)
		}
	}
}

extension SettingsKey where Payload == Bool {
	static func from(userDefaults: UserDefaults) -> Payload? { userDefaults.bool(forKey: keyName) }
	static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: keyName) }
}

extension SettingsKey where Payload == Data {
	static func from(userDefaults: UserDefaults) -> Payload? { userDefaults.data(forKey: keyName) }
	static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: keyName) }
}

extension SettingsKey where Payload == Int {
	static func from(userDefaults: UserDefaults) -> Payload? { userDefaults.integer(forKey: keyName) }
	static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: keyName) }
}

extension SettingsKey where Payload: Codable {
	static func from(userDefaults: UserDefaults) -> Payload? {
		guard let data = userDefaults.data(forKey: keyName) else { return nil }
		return try? JSONDecoder().decode(Payload.self, from: data)
	}
	
	static func set(_ value: Payload?, in userDefaults: UserDefaults) {
		guard let value, let data = try? JSONEncoder().encode(value) else {
			userDefaults.removeObject(forKey: keyName)
			return
		}
		userDefaults.set(data, forKey: keyName)
	}
}
