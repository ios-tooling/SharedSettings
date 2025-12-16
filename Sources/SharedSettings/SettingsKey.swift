//
//  SettingsKey.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import Foundation

public protocol SettingsKey<Payload>: Sendable {
	associatedtype Payload: Codable & Sendable
	static var defaultValue: Payload { get }
	static var name: String { get }
	
	nonisolated static func from(userDefaults: UserDefaults) -> Payload?
	nonisolated static func set(_ value: Payload?, in userDefaults: UserDefaults)
}

extension SettingsKey {
	public static var name: String { String(describing: self) }
	
}
