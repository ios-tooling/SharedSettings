//
//  SettingsKey+CloudKit.swift
//  SharedSettings
//
//  Created by Ben Gottlieb on 12/30/25.
//

import Foundation
import CloudKit

extension SettingsKey {
	static func saveCloudKitStore() { cloudKitKeyValueStore.synchronize() }
	static var cloudKitKeyValueStore: NSUbiquitousKeyValueStore { NSUbiquitousKeyValueStore.default }
}

extension SettingsKey where Payload == String {
	public static func fromCloudKit() -> Payload? { cloudKitKeyValueStore.string(forKey: name) }
	public static func setInCloudKit(_ value: Payload?) {
		cloudKitKeyValueStore.set(value, forKey: name)
		saveCloudKitStore()
	}
}

extension SettingsKey where Payload == Bool {
	public static func fromCloudKit() -> Payload? {
		cloudKitKeyValueStore.bool(forKey: name)
	}
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value, forKey: name) }
}

extension SettingsKey where Payload == URL {
	public static func fromCloudKit() -> Payload? { cloudKitKeyValueStore.url(forKey: name) }
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value, forKey: name) }
}

extension SettingsKey where Payload == [String] {
	public static func fromCloudKit() -> Payload? { cloudKitKeyValueStore.array(forKey: name) as? [String] }
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value, forKey: name) }
}

extension SettingsKey where Payload == Data {
	public static func fromCloudKit() -> Payload? { cloudKitKeyValueStore.data(forKey: name) }
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value, forKey: name) }
}

extension SettingsKey where Payload == Date {
	public static func fromCloudKit() -> Payload? { cloudKitKeyValueStore.object(forKey: name) as? Date }
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value, forKey: name) }
}

extension SettingsKey where Payload == Int {
	public static func fromCloudKit() -> Payload? {
		if cloudKitKeyValueStore.object(forKey: name) == nil { return nil }
		let raw = cloudKitKeyValueStore.longLong(forKey: name)
		return Int(raw)
	}
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value, forKey: name) }
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == String, Payload: Codable {
	public static func fromCloudKit() -> Payload? {
		guard let raw = cloudKitKeyValueStore.string(forKey: name) else { return nil }
		return Payload(rawValue: raw)
	}
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value?.rawValue, forKey: name) }
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == Int, Payload: Codable {
	public static func fromCloudKit() -> Payload? {
		if cloudKitKeyValueStore.object(forKey: name) == nil { return nil }
		let raw = cloudKitKeyValueStore.longLong(forKey: name)
		return Payload(rawValue: Int(raw))
	}
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value?.rawValue, forKey: name) }
}

extension SettingsKey where Payload == Double {
	public static func fromCloudKit() -> Payload? {
		if cloudKitKeyValueStore.object(forKey: name) == nil { return nil }
		return cloudKitKeyValueStore.double(forKey: name)
	}
	public static func setInCloudKit(_ value: Payload?) { cloudKitKeyValueStore.set(value, forKey: name) }
}

extension SettingsKey where Payload: Codable {
	public static func fromCloudKit() -> Payload? {
		guard let data = cloudKitKeyValueStore.data(forKey: name) else { return nil }
		return try? JSONDecoder().decode(Payload.self, from: data)
	}
	
	public static func setInCloudKit(_ value: Payload?) {
		guard let value else {
			cloudKitKeyValueStore.removeObject(forKey: name)
			return
		}

		if let data = try? JSONEncoder().encode(value) {
			cloudKitKeyValueStore.set(data, forKey: name)
		}
	}
}

extension NSUbiquitousKeyValueStore {
	func url(forKey key: String) -> URL? {
		guard let raw = string(forKey: key) else { return nil }
		return URL(string: raw)
	}
	
	func set(_ url: URL, forKey key: String) {
		set(url.absoluteString, forKey: key)
	}
}
