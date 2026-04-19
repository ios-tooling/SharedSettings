//
//  SecureURLStore.swift
//  SharedSettings
//
//  Persists security-scoped bookmarks so sandboxed file access can be
//  re-established across launches. Each bookmark is keyed by the URL's
//  path in a `[String: Data]` map stored under a single UserDefaults key.
//

import Foundation

public struct SecureURLStore: Sendable {
	public static let shared = SecureURLStore()

	public let userDefaults: UserDefaults
	public let defaultsKey: String

	/// Create a store. `defaultsKey` is the UserDefaults key under which the
	/// `[String: Data]` bookmark map is stored; callers that want to segregate
	/// bookmarks per-app or per-purpose should pass a distinct value.
	public init(
		userDefaults: UserDefaults = .standard,
		defaultsKey: String = "com.sharedsettings.secure-urls"
	) {
		self.userDefaults = userDefaults
		self.defaultsKey = defaultsKey
	}

	/// Persist a security-scoped bookmark for `url`. The URL must currently
	/// carry a security-scoped aura — from `NSOpenPanel`, a drop, `onOpenURL`,
	/// or a previous bookmark resolution. Called with a scope-less URL, the
	/// underlying `bookmarkData` call throws and this method silently no-ops.
	public func save(_ url: URL) {
		guard let data = try? url.bookmarkData(
			options: .withSecurityScope,
			includingResourceValuesForKeys: nil,
			relativeTo: nil
		) else { return }
		var bookmarks = current
		bookmarks[url.path] = data
		write(bookmarks)
	}

	/// Resolve a previously-saved bookmark to a security-scope-aware URL.
	/// Returns nil if no bookmark was ever stored for this path or if
	/// resolution fails. Stale bookmarks are refreshed in place.
	public func resolve(_ url: URL) -> URL? {
		let bookmarks = current
		guard let data = bookmarks[url.path] else { return nil }
		var isStale = false
		guard let resolved = try? URL(
			resolvingBookmarkData: data,
			options: .withSecurityScope,
			relativeTo: nil,
			bookmarkDataIsStale: &isStale
		) else { return nil }

		if isStale { save(resolved) }
		return resolved
	}

	/// Drop the bookmark for `url` if one is stored.
	public func remove(_ url: URL) {
		var bookmarks = current
		bookmarks.removeValue(forKey: url.path)
		write(bookmarks)
	}

	private var current: [String: Data] {
		(userDefaults.dictionary(forKey: defaultsKey) as? [String: Data]) ?? [:]
	}

	private func write(_ bookmarks: [String: Data]) {
		userDefaults.set(bookmarks, forKey: defaultsKey)
	}
}

public extension SecureURLStore {
	/// Shortcut for `SecureURLStore.shared.save(url)`.
	static func save(_ url: URL) { shared.save(url) }

	/// Shortcut for `SecureURLStore.shared.resolve(url)`.
	static func resolve(_ url: URL) -> URL? { shared.resolve(url) }

	/// Shortcut for `SecureURLStore.shared.remove(url)`.
	static func remove(_ url: URL) { shared.remove(url) }
}
