//
//  ObservedSettings.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/15/25.
//

import SwiftUI

@Observable @MainActor public class ObservedSettings {
	public static let instance = ObservedSettings()

	internal init(settings: SharedSettings = SharedSettings.instance) {
		self.settings = settings
		externalChangeToken = NotificationCenter.default.addObserver(
			forName: SharedSettings.didChangeExternallyNotification,
			object: nil,
			queue: nil
		) { [weak self] _ in
			Task { @MainActor [weak self] in
				self?.invalidate()
			}
		}
	}

	deinit {
		if let token = externalChangeToken {
			NotificationCenter.default.removeObserver(token)
		}
	}

	@ObservationIgnored nonisolated(unsafe) private var externalChangeToken: NSObjectProtocol?

	private func invalidate() {
		withMutation(keyPath: \.settings) { }
	}

	let settings: SharedSettings
	
	public func binding<Key: SettingsKey>(_ key: Key.Type) -> Binding<Key.Payload?> {
		Binding {
			self[key]
		} set: { newValue in
			self[key] = newValue
		}

	}
		
	public subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload? {
		get {
			access(keyPath: \.self)
			return settings[key]
		}
		
		set {
			withMutation(keyPath: \.self) {
				settings.set(newValue, forKey: key)
			}
		}
	}

}

