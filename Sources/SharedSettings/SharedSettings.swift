//
//  SharedSettings.swift
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation
import os

extension UserDefaults: @retroactive @unchecked Sendable { }

nonisolated public final class SharedSettings: Sendable {
	public static nonisolated let instance = SharedSettings()
	
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
	
	public nonisolated static subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload? {
		get { instance[key] }
		set { instance[key] = newValue }
	}

	nonisolated subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload? {
		get {
			switch key.location {
			case .userDefaults:
				return defaultsLock.withLock { userDefaults in
					if let userDefaults {
						return key.from(userDefaults: userDefaults)
					}
					return nil
				}
				
			case .cloudKit:
				return key.fromCloudKit()
				
			case .keychain:
				return key.fromKeychain()
			}
		}
		set {
			switch key.location {
			case .userDefaults:
				defaultsLock.withLock { userDefaults in
					if let userDefaults {
						key.set(newValue, in: userDefaults)
					}
				}
				
			case .cloudKit:
				key.setInCloudKit(newValue)
				
			case .keychain:
				key.setInKeychain(newValue)
			}
		}
	}
	
}
