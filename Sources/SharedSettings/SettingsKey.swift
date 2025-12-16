//
//  SettingsKey.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation

//public protocol SettableSettingValue { }
//
//extension String: SettableSettingValue { }
//
//
//extension String: SettableSettingValue { }
//extension Bool: SettableSettingValue { }
//extension Date: SettableSettingValue { }
//extension Int: SettableSettingValue { }
//extension Double: SettableSettingValue { }
//extension Data: SettableSettingValue { }
//extension Encodable: SettableSettingValue { }
//
//extension Optional: SettableSettingValue where Wrapped: SettableSettingValue { }

public protocol SettingsKey<Payload> {
	associatedtype Payload: Codable
	static var defaultValue: Payload { get }
	
	nonisolated static func from(userDefaults: UserDefaults) -> Payload?
	nonisolated static func set(_ value: Payload?, in userDefaults: UserDefaults)
}

extension SettingsKey {
	public static var keyName: String { String(describing: self) }
	
}
