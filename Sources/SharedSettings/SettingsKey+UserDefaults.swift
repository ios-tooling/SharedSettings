//
//  Settings+UserDefaults.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/16/25.
//

import Foundation

extension SettingsKey where Payload == String {
	public static func from(userDefaults: UserDefaults) -> Payload? {
		userDefaults.string(forKey: name)
	}
	
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) {
		userDefaults.set(value, forKey: name)
	}
}

extension SettingsKey where Payload == Bool {
	public static func from(userDefaults: UserDefaults) -> Payload? {
		if userDefaults.object(forKey: name) == nil { return nil }
		return userDefaults.bool(forKey: name)
	}
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: name) }
}

extension SettingsKey where Payload == URL {
	public static func from(userDefaults: UserDefaults) -> Payload? { userDefaults.url(forKey: name) }
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: name) }
}

extension SettingsKey where Payload == [String] {
	public static func from(userDefaults: UserDefaults) -> Payload? { userDefaults.stringArray(forKey: name) }
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: name) }
}

extension SettingsKey where Payload == Data {
	public static func from(userDefaults: UserDefaults) -> Payload? { userDefaults.data(forKey: name) }
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: name) }
}

extension SettingsKey where Payload == Int {
	public static func from(userDefaults: UserDefaults) -> Payload? {
		if userDefaults.object(forKey: name) == nil { return nil }
		return userDefaults.integer(forKey: name)
	}
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: name) }
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == String {
	public static func from(userDefaults: UserDefaults) -> Payload? {
		guard let raw = userDefaults.string(forKey: name) else { return nil }
		return Payload(rawValue: raw)
	}
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value?.rawValue, forKey: name) }
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == Int {
	public static func from(userDefaults: UserDefaults) -> Payload? {
		if userDefaults.object(forKey: name) == nil { return nil }
		let raw = userDefaults.integer(forKey: name)
		return Payload(rawValue: raw)
	}
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value?.rawValue, forKey: name) }
}

extension SettingsKey where Payload == Double {
	public static func from(userDefaults: UserDefaults) -> Payload? {
		if userDefaults.object(forKey: name) == nil { return nil }
		return userDefaults.double(forKey: name)
	}
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) { userDefaults.set(value, forKey: name) }
}

extension SettingsKey where Payload: Codable {
	public static func from(userDefaults: UserDefaults) -> Payload? {
		guard let data = userDefaults.data(forKey: name) else { return nil }
		return try? JSONDecoder().decode(Payload.self, from: data)
	}
	
	public static func set(_ value: Payload?, in userDefaults: UserDefaults) {
		guard let value else {
			userDefaults.removeObject(forKey: name)
			return
		}

		if let data = try? JSONEncoder().encode(value) {
			userDefaults.set(data, forKey: name)
		}
	}
}
