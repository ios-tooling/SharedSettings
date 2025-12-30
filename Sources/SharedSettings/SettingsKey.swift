//
//  SettingsKey.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation

public enum SettingsLocation: Sendable { case userDefaults, cloudKit }

public protocol SettingsKey<Payload>: Sendable {
	associatedtype Payload: Codable & Sendable
	static var defaultValue: Payload { get }
	static var name: String { get }
	static var location: SettingsLocation { get }
	
	nonisolated static func from(userDefaults: UserDefaults) -> Payload?
	nonisolated static func set(_ value: Payload?, in userDefaults: UserDefaults)
	nonisolated static func fromCloudKit() -> Payload?
	nonisolated static func setInCloudKit(_ value: Payload?)
}

extension SettingsKey {
	public static var name: String { String(describing: self) }
}

public extension SettingsKey {
	static var location: SettingsLocation { .userDefaults }
}
