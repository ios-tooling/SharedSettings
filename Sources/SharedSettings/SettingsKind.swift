//
//  SettingsKind.swift
//  SharedSettings
//
//  What a setting is *for* — an axis orthogonal to where it's stored.
//

import Foundation
import os

/// Who a setting is meant for, and therefore where it shows up.
///
/// This is independent of ``SettingsLocation``: a `.developer` setting still picks a
/// backing store, while a `.buildTime` setting has no store at all.
public enum SettingsKind: String, Sendable, CaseIterable {
	/// A user-facing preference, exposed in the app's settings UI to everyone. The default.
	case user

	/// An internal flag for testing, listed only where ``SharedSettings/isDeveloperBuild`` allows.
	/// Reads and writes behave normally in every build — the kind gates *visibility*, not storage.
	case developer

	/// Fixed at compile time. Reads always return `defaultValue`; writes are ignored.
	case buildTime

	public var title: String {
		switch self {
		case .user: "Settings"
		case .developer: "Developer"
		case .buildTime: "Build"
		}
	}
}

public extension SharedSettings {
	/// Gates the developer-settings UI (see ``DeveloperSettingsScreen``).
	///
	/// Defaults to `true` in DEBUG builds and `false` otherwise. Set it at launch to expose
	/// developer settings in a TestFlight or internal build, or behind a hidden gesture:
	///
	/// ```swift
	/// SharedSettings.isDeveloperBuild = Bundle.main.isInternalBuild
	/// ```
	///
	/// It deliberately has no effect on reading or writing a `.developer` setting — a value
	/// written by a tester keeps working in a release build. Only the UI is gated.
	nonisolated static var isDeveloperBuild: Bool {
		get { developerBuildLock.withLock { $0 } }
		set { developerBuildLock.withLock { $0 = newValue } }
	}
}

extension SharedSettings {
	// SwiftPM/Xcode compile package targets with the app's configuration, so DEBUG here
	// tracks the app's build configuration.
	private static let developerBuildLock: OSAllocatedUnfairLock<Bool> = {
		#if DEBUG
			.init(initialState: true)
		#else
			.init(initialState: false)
		#endif
	}()
}
