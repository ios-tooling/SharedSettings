//
//  ObservedSettings.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import SwiftUI

@Observable @MainActor public class ObservedSettings {
	public static let instance = ObservedSettings()
	
	internal init(settings: Settings = Settings.instance) {
		self.settings = settings
	}

	let settings: Settings
		
	public subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload? {
		get {
			access(keyPath: \.self)
			return settings[key]
		}
		
		set {
			withMutation(keyPath: \.self) {
				settings[key] = newValue
			}
		}
	}

}

