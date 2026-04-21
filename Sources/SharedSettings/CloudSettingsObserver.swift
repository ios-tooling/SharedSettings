//
//  CloudSettingsObserver.swift
//  SharedSettings
//

import Foundation

extension SharedSettings {
	public static let didChangeExternallyNotification = Notification.Name(
		"com.sharedsettings.didChangeExternally"
	)

	public static let changedKeysUserInfoKey = "SharedSettings.changedKeys"
	public static let changeReasonUserInfoKey = "SharedSettings.changeReason"
}

extension Notification {
	public var sharedSettingsChangedKeys: [String]? {
		userInfo?[SharedSettings.changedKeysUserInfoKey] as? [String]
	}

	public var sharedSettingsChangeReason: Int? {
		userInfo?[SharedSettings.changeReasonUserInfoKey] as? Int
	}
}

enum CloudSettingsObserver {
	nonisolated(unsafe) private static let token: NSObjectProtocol? = {
		let store = NSUbiquitousKeyValueStore.default
		_ = store.synchronize()
		return NotificationCenter.default.addObserver(
			forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
			object: store,
			queue: nil
		) { note in
			var forwarded: [AnyHashable: Any] = [:]
			if let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
				forwarded[SharedSettings.changedKeysUserInfoKey] = keys
			}
			if let reason = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int {
				forwarded[SharedSettings.changeReasonUserInfoKey] = reason
			}
			NotificationCenter.default.post(
				name: SharedSettings.didChangeExternallyNotification,
				object: nil,
				userInfo: forwarded
			)
		}
	}()

	static func start() { _ = token }
}
