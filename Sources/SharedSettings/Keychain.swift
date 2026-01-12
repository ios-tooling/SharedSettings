//
//  File.swift
//  SharedSettings
//
//  Created by Ben Gottlieb on 1/11/26.
//

import Security
import Foundation
import Combine

extension CFString: @retroactive @unchecked Sendable { }

struct Keychain {
	enum KeychainError: Error, LocalizedError {
		case systemError(Int), badlyFormattedDate, badlyFormattedURL
		
		var errorDescription: String? {
			switch self {
			case .systemError(let code): return "Keychain error with code \(code)"
			case .badlyFormattedDate: return "Value in keychain was not a valid Date"
			case .badlyFormattedURL: return "Value in keychain was not a valid URL"
			}
		}
	}
	
	nonisolated static func set(_ value: String?, forKey key: String, withAccess access: AccessOptions? = nil) throws { try set(value?.data(using: String.Encoding.utf8), forKey: key, withAccess: access) }
	nonisolated static func set(_ value: Double, forKey key: String, withAccess access: AccessOptions? = nil) throws { try set("\(value)", forKey: key, withAccess: access) }
	nonisolated static func set(_ value: Int, forKey key: String, withAccess access: AccessOptions? = nil) throws { try set("\(value)", forKey: key, withAccess: access) }
	nonisolated static func set(_ url: URL?, forKey key: String, withAccess access: AccessOptions? = nil) throws { try set(url?.absoluteString, forKey: key, withAccess: access) }
	
	nonisolated static func set<Payload: Encodable>(_ value: Payload?, forKey key: String, withAccess access: AccessOptions? = nil) throws {
		guard let value else {
			try delete(key)
			return
		}
		
		let data = try JSONEncoder().encode(value)
		try set(data, forKey: key, withAccess: access)
	}
	
	nonisolated static func set(_ date: Date?, forKey key: String, withAccess access: AccessOptions? = nil) throws {
		guard let date else {
			try delete(key)
			return
		}
		
		let string = ISO8601DateFormatter().string(from: date)
		try set(string, forKey: key, withAccess: access)
	}
	
	nonisolated static func set(_ value: Data?, forKey key: String, withAccess access: AccessOptions? = nil) throws {
		try delete(key) // Delete any existing key before saving it
		
		guard let value else { return }
		
		let query: [String: Sendable] = [
			Constants.keychainClass: kSecClassGenericPassword,
			Constants.attrAccount: key,
			Constants.valueData: value,
			Constants.accessible: (access ?? .default).value
		]
		
		let result = SecItemAdd(query as CFDictionary, nil)
		
		if result != noErr { throw KeychainError.systemError(Int(result)) }
	}

	nonisolated static func set(_ value: Bool, forKey key: String, withAccess access: AccessOptions? = nil) throws {
		let bytes: [UInt8] = value ? [1] : [0]
		let data = Data(bytes)
		
		try set(data, forKey: key, withAccess: access)
	}
	
	static nonisolated func string(forKey key: String) throws -> String? {
		if let data = try data(forKey: key), let currentString = String(data: data, encoding: .utf8) {
			return currentString
		}
		
		return nil
	}
	
	static nonisolated func decoded<Payload: Decodable>(forKey key: String) throws -> Payload? {
		guard let data = try data(forKey: key) else { return nil }
		return try JSONDecoder().decode(Payload.self, from: data)
	}
	
	static nonisolated func url(forKey key: String) throws -> URL? {
		guard let string = try string(forKey: key) else { return nil }
		guard let url = URL(string: string) else { throw KeychainError.badlyFormattedURL }
		return url
	}
	
	static nonisolated func date(forKey key: String) throws -> Date? {
		guard let string = try string(forKey: key) else { return nil }
			
		if let date = ISO8601DateFormatter().date(from: string) { return date }
		throw KeychainError.badlyFormattedDate
	}
	
	static nonisolated func double(forKey key: String) throws -> Double? {
		if let string = try string(forKey: key) {
			return Double(string)
		}
		
		return nil
	}
	
	static nonisolated func int(forKey key: String) throws -> Int? {
		if let string = try string(forKey: key) {
			return Int(string)
		}
		
		return nil
	}

	static nonisolated func data(forKey key: String) throws -> Data? {
		var result: AnyObject?
		let query: [String: Sendable] = [
			Constants.keychainClass: kSecClassGenericPassword,
			Constants.attrAccount: key,
			Constants.returnData: true,
			Constants.matchLimit: kSecMatchLimitOne
		]
		
		let errCode = withUnsafeMutablePointer(to: &result) {
			SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
		}
		
		switch errCode {
		case noErr: break
		case -34018, -25300: return nil
		default: throw KeychainError.systemError(Int(errCode))
		}
		
		return result as? Data
	}
	
	static nonisolated func bool(forKey key: String) throws -> Bool? {
		guard let data = try data(forKey: key) else { return nil }
		guard let firstBit = data.first else { return nil }
		return firstBit == 1
	}
	
	nonisolated static func delete(_ key: String) throws {
		let query: [String: Sendable] = [
			Constants.keychainClass: kSecClassGenericPassword,
			Constants.attrAccount: key
		]
		let errCode = SecItemDelete(query as CFDictionary)
		
		switch errCode {
		case noErr: break
		case -34018, -25300: break			// errSecMissingEntitlement, we tried to delete something that wasn't there. NBD.
		default: throw KeychainError.systemError(Int(errCode))
		}
	}
}

extension Keychain {
	struct Constants {
		nonisolated static var accessGroup: String { kSecAttrAccessGroup as String }
		nonisolated static var accessible: String { kSecAttrAccessible as String }
		nonisolated static var attrAccount: String { kSecAttrAccount as String }
		nonisolated static var attrSynchronizable: String { kSecAttrSynchronizable as String }
		nonisolated static var keychainClass: String { kSecClass as String }
		nonisolated static var matchLimit: String { kSecMatchLimit as String }
		nonisolated static var returnData: String { kSecReturnData as String }
		nonisolated static var valueData: String { kSecValueData as String }
	}
	
	enum AccessOptions { case accessibleWhenUnlocked, accessibleWhenUnlockedThisDeviceOnly, accessibleAfterFirstUnlock, accessibleAfterFirstUnlockThisDeviceOnly, accessibleWhenPasscodeSetThisDeviceOnly, accessibleAlwaysThisDeviceOnly
		
		static var `default`: AccessOptions { .accessibleAfterFirstUnlock }
		
		var value: String {
			switch self {
			case .accessibleWhenUnlocked: kSecAttrAccessibleWhenUnlocked as String
			case .accessibleWhenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
			case .accessibleAfterFirstUnlock: kSecAttrAccessibleAfterFirstUnlock as String
			case .accessibleAfterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
				//case .accessibleAlways: kSecAttrAccessibleAlways as String
			case .accessibleWhenPasscodeSetThisDeviceOnly: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String
			case .accessibleAlwaysThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
			}
		}
	}
}


