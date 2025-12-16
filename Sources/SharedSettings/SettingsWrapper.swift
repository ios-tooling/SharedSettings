//
//  SettingsKey.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import SwiftUI

@propertyWrapper @MainActor struct Setting<Key: SettingsKey>: DynamicProperty {
	init(_ key: Key.Type) {
		self.key = key
	}
	
	let key: Key.Type
	var settings = ObservedSettings.instance
	
	var wrappedValue: Key.Payload {
		get {
			settings[key] ?? Key.defaultValue
		}
		nonmutating set {
			settings[key] = newValue
		}
	}
	
	var projectedValue: Binding<Key.Payload> {
		.init {
			wrappedValue
		} set: { newValue in
			settings[key] = newValue
		}

	}
}
