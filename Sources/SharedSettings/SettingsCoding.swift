//
//  SettingsCoding.swift
//  SharedSettings
//
//  The one JSON encoder/decoder pair every Codable payload goes through —
//  UserDefaults, iCloud KVS, and the keychain alike. Apps that store dates
//  inside Codable payloads should pick a strategy here before anything is
//  written: the default `JSONEncoder` renders a Date as seconds since 2001,
//  which is fine until the day you want to read the bytes anywhere else, and
//  changing strategy later rewrites every stored value.
//

import Foundation
import os

public struct SettingsCoding: Sendable {
	public var makeEncoder: @Sendable () -> JSONEncoder
	public var makeDecoder: @Sendable () -> JSONDecoder

	public init(makeEncoder: @escaping @Sendable () -> JSONEncoder, makeDecoder: @escaping @Sendable () -> JSONDecoder) {
		self.makeEncoder = makeEncoder
		self.makeDecoder = makeDecoder
	}

	/// Foundation's defaults: dates as seconds since 2001. What every version
	/// of this package has used.
	public static let foundationDefault = SettingsCoding(makeEncoder: { JSONEncoder() }, makeDecoder: { JSONDecoder() })

	/// Dates as ISO 8601 strings — readable by anything, comparable as text.
	public static let iso8601 = SettingsCoding(makeEncoder: {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}, makeDecoder: {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	})
}

extension SharedSettings {
	private static let codingLock = OSAllocatedUnfairLock<SettingsCoding>(initialState: .foundationDefault)

	/// The coder used for every Codable payload. Set it once, at launch,
	/// before any setting is read; it is not a per-key choice.
	public static var coding: SettingsCoding {
		get { codingLock.withLock { $0 } }
		set { codingLock.withLock { $0 = newValue } }
	}

	static func encode<Payload: Encodable>(_ value: Payload) throws -> Data { try coding.makeEncoder().encode(value) }
	static func decode<Payload: Decodable>(_ type: Payload.Type, from data: Data) throws -> Payload { try coding.makeDecoder().decode(type, from: data) }
}

/// Lets the stores tell `.some(nil)` from `.some(value)` for an Optional
/// payload: a cleared Optional removes the key instead of storing JSON `null`,
/// so "absent" and "null" are the same thing on every store.
protocol SettingsOptionalPayload {
	var isNilPayload: Bool { get }
}

extension Optional: SettingsOptionalPayload {
	var isNilPayload: Bool { self == nil }
}

extension SettingsKey {
	/// True when `value` should clear the key: nil, or an Optional payload holding nil.
	static func clears(_ value: Payload?) -> Bool {
		guard let value else { return true }
		return (value as? SettingsOptionalPayload)?.isNilPayload ?? false
	}
}
