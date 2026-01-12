//
//  Settings+UserDefaults.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/16/25.
//

import Foundation

extension SettingsKey {
	static func reportKeychainError(_ error: Error, for name: String) {
		print("Keychain failed: \(error.localizedDescription) for \(name)")
	}
}

extension SettingsKey where Payload == String {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.string(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}
	
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

extension SettingsKey where Payload == Bool {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.bool(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

extension SettingsKey where Payload == URL {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.url(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

//extension SettingsKey where Payload == [String] {
//	public static func fromKeychain() -> Payload? { nil }
//	public static func setInKeychain(_ value: Payload?) {
//		do {
//			return try Keychain.set(value, forKey: name)
//		} catch {
//			reportKeychainError(error, for: name)
//		}
//	}
//}

extension SettingsKey where Payload == Data {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.data(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}
	
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

extension SettingsKey where Payload == Date {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.date(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}
	
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

extension SettingsKey where Payload == Int {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.int(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}

	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == String, Payload: Codable {
	public static func fromKeychain() -> Payload? {
		do {
			guard let string = try Keychain.string(forKey: name) else { return nil }
			return Payload(rawValue: string)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}

	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value?.rawValue, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
		
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == Int, Payload: Codable {
	public static func fromKeychain() -> Payload? {
		do {
			guard let int = try Keychain.int(forKey: name) else { return nil }
			return Payload(rawValue: int)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}

	}
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

extension SettingsKey where Payload == Double {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.double(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}

	}
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}
	}
}

extension SettingsKey where Payload: Codable {
	public static func fromKeychain() -> Payload? {
		do {
			return try Keychain.decoded(forKey: name)
		} catch {
			reportKeychainError(error, for: name)
			return nil
		}
	}
	
	public static func setInKeychain(_ value: Payload?) {
		do {
			return try Keychain.set(value, forKey: name)
		} catch {
			reportKeychainError(error, for: name)
		}

	}
}
