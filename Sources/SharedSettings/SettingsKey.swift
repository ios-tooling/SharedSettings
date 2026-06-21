//
//  SettingsKey.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation

public enum SettingsLocation: Sendable { case userDefaults, cloudKit, keychain, memory }

public protocol SettingsKey<Payload>: Sendable {
	associatedtype Payload: Sendable
	static var defaultValue: Payload { get }
	static var name: String { get }
	static var location: SettingsLocation { get }

	nonisolated static func from(userDefaults: UserDefaults) -> Payload?
	nonisolated static func set(_ value: Payload?, in userDefaults: UserDefaults)
	nonisolated static func fromCloudKit() -> Payload?
	nonisolated static func setInCloudKit(_ value: Payload?)
	nonisolated static func fromKeychain() -> Payload?
	nonisolated static func setInKeychain(_ value: Payload?)
}

public extension SettingsKey {
	static func from(userDefaults: UserDefaults) -> Payload? { nil }
	static func set(_ value: Payload?, in userDefaults: UserDefaults) { }
	static func fromCloudKit() -> Payload? { nil }
	static func setInCloudKit(_ value: Payload?) { }
	static func fromKeychain() -> Payload? { nil }
	static func setInKeychain(_ value: Payload?) { }
}

extension SettingsKey {
	public static var name: String { String(describing: self) }
}

public extension SettingsKey {
	static var location: SettingsLocation { .userDefaults }
}

public extension SettingsKey {
	static nonisolated var sharedValue: Payload {
		get { SharedSettings[Self.self] }
		set { SharedSettings[Self.self] = newValue }
	}
}
