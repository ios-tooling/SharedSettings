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
	static var cloudKitKeyValueStore: NSUbiquitousKeyValueStore {
		// Attach the external-change observer the first time cloud storage is
		// actually used. Idempotent — backed by a lazy static.
		CloudSettingsObserver.start()
		return NSUbiquitousKeyValueStore.default
	}

	/// Serves a read from `CloudSettingsCache`, running `load` against the store only on a miss.
	static func cachedFromCloudKit(_ load: () -> Payload?) -> Payload? {
		CloudSettingsCache.shared.value(forKey: name, load: load)
	}

	/// Records a write in `CloudSettingsCache`, so the next read returns it without a store hit.
	static func cacheCloudKitWrite(_ value: Payload?) {
		CloudSettingsCache.shared.store(value, forKey: name)
	}
}

extension SettingsKey where Payload == String {
	public static func fromCloudKit() -> Payload? { cachedFromCloudKit { cloudKitKeyValueStore.string(forKey: name) } }
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value, forKey: name)
		saveCloudKitStore()
	}
}

extension SettingsKey where Payload == Bool {
	public static func fromCloudKit() -> Payload? {
		cachedFromCloudKit {
			if cloudKitKeyValueStore.object(forKey: name) == nil { return nil }
			return cloudKitKeyValueStore.bool(forKey: name)
		}
	}
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		if let value { cloudKitKeyValueStore.set(value, forKey: name) } else { cloudKitKeyValueStore.removeObject(forKey: name) }
	}
}

extension SettingsKey where Payload == URL {
	public static func fromCloudKit() -> Payload? { cachedFromCloudKit { cloudKitKeyValueStore.url(forKey: name) } }
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value, forKey: name)
	}
}

extension SettingsKey where Payload == [String] {
	public static func fromCloudKit() -> Payload? { cachedFromCloudKit { cloudKitKeyValueStore.array(forKey: name) as? [String] } }
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value, forKey: name)
	}
}

extension SettingsKey where Payload == Data {
	public static func fromCloudKit() -> Payload? { cachedFromCloudKit { cloudKitKeyValueStore.data(forKey: name) } }
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value, forKey: name)
	}
}

extension SettingsKey where Payload == Date {
	public static func fromCloudKit() -> Payload? { cachedFromCloudKit { cloudKitKeyValueStore.object(forKey: name) as? Date } }
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value, forKey: name)
	}
}

extension SettingsKey where Payload == Int {
	public static func fromCloudKit() -> Payload? {
		cachedFromCloudKit {
			if cloudKitKeyValueStore.object(forKey: name) == nil { return nil }
			return Int(cloudKitKeyValueStore.longLong(forKey: name))
		}
	}
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value, forKey: name)
	}
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == String, Payload: Codable {
	public static func fromCloudKit() -> Payload? {
		cachedFromCloudKit {
			guard let raw = cloudKitKeyValueStore.string(forKey: name) else { return nil }
			return Payload(rawValue: raw)
		}
	}
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value?.rawValue, forKey: name)
	}
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == Int, Payload: Codable {
	public static func fromCloudKit() -> Payload? {
		cachedFromCloudKit {
			if cloudKitKeyValueStore.object(forKey: name) == nil { return nil }
			return Payload(rawValue: Int(cloudKitKeyValueStore.longLong(forKey: name)))
		}
	}
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value?.rawValue, forKey: name)
	}
}

extension SettingsKey where Payload == Double {
	public static func fromCloudKit() -> Payload? {
		cachedFromCloudKit {
			if cloudKitKeyValueStore.object(forKey: name) == nil { return nil }
			return cloudKitKeyValueStore.double(forKey: name)
		}
	}
	public static func setInCloudKit(_ value: Payload?) {
		cacheCloudKitWrite(value)
		cloudKitKeyValueStore.set(value, forKey: name)
	}
}

extension SettingsKey where Payload: Codable {
	public static func fromCloudKit() -> Payload? {
		cachedFromCloudKit {
			guard let data = cloudKitKeyValueStore.data(forKey: name) else { return nil }
			return try? SharedSettings.decode(Payload.self, from: data)
		}
	}
	
	public static func setInCloudKit(_ value: Payload?) {
		guard let value, !clears(value) else {
			cacheCloudKitWrite(nil)
			cloudKitKeyValueStore.removeObject(forKey: name)
			return
		}

		if let data = try? SharedSettings.encode(value) {
			cacheCloudKitWrite(value)
			cloudKitKeyValueStore.set(data, forKey: name)
		} else {
			CloudSettingsCache.shared.invalidate([name])   // nothing was written; read the store again
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
