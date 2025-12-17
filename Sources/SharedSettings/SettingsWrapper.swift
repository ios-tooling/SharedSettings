//
//  SettingsKey.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import SwiftUI

@propertyWrapper @MainActor public struct Setting<Key: SettingsKey>: DynamicProperty {
	public init(_ key: Key.Type) {
		self.key = key
		self.settings = ObservedSettings.instance
	}
	
	internal init(_ key: Key.Type, settings: ObservedSettings) {
		self.key = key
		self.settings = settings
	}
	
	let key: Key.Type
	let settings: ObservedSettings
	
	public var wrappedValue: Key.Payload {
		get {
			settings[key] ?? Key.defaultValue
		}
		nonmutating set {
			settings[key] = newValue
		}
	}
	
	public var projectedValue: Binding<Key.Payload> {
		.init {
			wrappedValue
		} set: { newValue in
			settings[key] = newValue
		}

	}
}
