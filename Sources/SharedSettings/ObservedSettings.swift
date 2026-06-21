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
		) { [weak self] note in
			let keys = note.sharedSettingsChangedKeys
			Task { @MainActor [weak self] in self?.invalidate(keys) }
		}
	}

	deinit {
		if let token = externalChangeToken {
			NotificationCenter.default.removeObserver(token)
		}
	}

	@ObservationIgnored nonisolated(unsafe) private var externalChangeToken: NSObjectProtocol?
	@ObservationIgnored private let settings: SharedSettings

	// One observable token per key name. Swift Observation can only track real keyPaths, not
	// dynamic string keys, so each key gets its own tiny @Observable token: reading a key tracks
	// its token, and a change bumps only that token. That gives per-key granularity — a change to
	// one setting refreshes only the views that read it, not every settings-bound view.
	@Observable @MainActor final class KeyToken { var version = 0 }
	@ObservationIgnored private var tokens: [String: KeyToken] = [:]

	private func token(for name: String) -> KeyToken {
		if let token = tokens[name] { return token }
		let token = KeyToken()
		tokens[name] = token
		return token
	}

	// Bump only tokens that exist — a key nobody has read has no observers to refresh. `nil` keys
	// (a change source that didn't say what changed) conservatively refreshes every observed key.
	private func invalidate(_ names: [String]?) {
		if let names {
			for name in names { tokens[name]?.version &+= 1 }
		} else {
			for token in tokens.values { token.version &+= 1 }
		}
	}

	public func binding<Key: SettingsKey>(_ key: Key.Type) -> Binding<Key.Payload?> {
		Binding {
			self[key]
		} set: { newValue in
			self[key] = newValue
		}
	}

	public subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload? {
		get {
			_ = token(for: key.name).version   // track this key's token
			return settings[key]
		}
		set {
			settings.set(newValue, forKey: key)
			tokens[key.name]?.version &+= 1    // covers stores that don't post a change notification
		}
	}
}
