//
//  Settings+UserDefaults.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/16/25.
//

import Foundation

extension SettingsKey where Payload == String {
	public static func fromKeychain() -> Payload? {
		nil
	}
	
	public static func setInKeychain(_ value: Payload?) {
	}
}

extension SettingsKey where Payload == Bool {
	public static func fromKeychain() -> Payload? {
		return nil
	}
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload == URL {
	public static func fromKeychain() -> Payload? { nil }
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload == [String] {
	public static func fromKeychain() -> Payload? { nil }
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload == Data {
	public static func fromKeychain() -> Payload? { nil }
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload == Date {
	public static func fromKeychain() -> Payload? { nil }
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload == Int {
	public static func fromKeychain() -> Payload? {
		nil
	}
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == String, Payload: Codable {
	public static func fromKeychain() -> Payload? {
		nil
	}
	public static func setInKeychain(_ value: Payload?) { }
		
}

extension SettingsKey where Payload: RawRepresentable, Payload.RawValue == Int, Payload: Codable {
	public static func fromKeychain() -> Payload? {
		nil
	}
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload == Double {
	public static func fromKeychain() -> Payload? {
		nil
	}
	public static func setInKeychain(_ value: Payload?) {  }
}

extension SettingsKey where Payload: Codable {
	public static func fromKeychain() -> Payload? {
		nil
	}
	
	public static func setInKeychain(_ value: Payload?) {
		guard let value else {
			return
		}

	}
}
