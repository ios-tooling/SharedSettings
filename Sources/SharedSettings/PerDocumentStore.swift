//
//  PerDocumentStore.swift
//  SharedSettings
//

import Foundation

/// Generic per-document state store backed by a `SettingsKey` whose payload is
/// `[String: Value]`. The dictionary is keyed by `"parentDir/filename"` so that
/// state survives the document being moved to a different absolute path.
///
/// Usage:
/// ```swift
/// struct MyStore {
///     static let shared = MyStore()
///     private let store = PerDocumentStore<MySettingsKey, Bool>()
///
///     func value(for url: URL) -> Bool? { store.value(for: url) }
///     func setValue(_ v: Bool, for url: URL) { store.setValue(v, for: url) }
/// }
/// ```
public struct PerDocumentStore<Key: SettingsKey, Value: Codable & Sendable>
	where Key.Payload == [String: Value] {

	public init() {}

	public func value(for url: URL) -> Value? {
		Key.sharedValue[url.perDocumentKey]
	}

	public func setValue(_ value: Value?, for url: URL) {
		var map = Key.sharedValue
		if let value {
			map[url.perDocumentKey] = value
		} else {
			map.removeValue(forKey: url.perDocumentKey)
		}
		Key.sharedValue = map
	}
}

public extension URL {
	/// A stable, path-agnostic key for per-document storage: `"parentDir/filename"`.
	/// Survives the document being moved between directories at the same level.
	var perDocumentKey: String {
		"\(deletingLastPathComponent().lastPathComponent)/\(lastPathComponent)"
	}
}
