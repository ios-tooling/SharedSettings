//
//  SharedSettings+AppGroup.swift
//
//  Created by Ben Gottlieb on 8/8/26.
//

import Foundation

extension SharedSettings {
	/// Points this instance at an App Group defaults suite so every target
	/// with the group's entitlement — app, widgets, app extensions — reads
	/// and writes the same values. Without this, each process silently gets
	/// its own `.standard` store. Call once, early in each process, before
	/// the first settings access.
	///
	/// `migrating` lists keys to copy from the process's standard defaults
	/// into the suite (only where the suite has no value yet), so adopting an
	/// App Group doesn't strand values written by earlier builds.
	///
	/// Returns `false` when the suite can't be created — typically a missing
	/// or misspelled App Group entitlement on the calling target — in which
	/// case the current store is left unchanged.
	@discardableResult
	public func use(appGroup identifier: String, migrating keyNames: [String] = []) -> Bool {
		guard let group = UserDefaults(suiteName: identifier) else { return false }
		let standard = UserDefaults.standard
		for name in keyNames where group.object(forKey: name) == nil {
			if let value = standard.object(forKey: name) {
				group.set(value, forKey: name)
			}
		}
		set(userDefaults: group)
		return true
	}

	/// Key-typed variant of `use(appGroup:migrating:)`.
	@discardableResult
	public func use(appGroup identifier: String, migrating keys: [any SettingsKey.Type]) -> Bool {
		use(appGroup: identifier, migrating: keys.map { $0.name })
	}

	/// Convenience for the shared instance.
	@discardableResult
	public static func use(appGroup identifier: String, migrating keys: [any SettingsKey.Type] = []) -> Bool {
		instance.use(appGroup: identifier, migrating: keys)
	}
}
