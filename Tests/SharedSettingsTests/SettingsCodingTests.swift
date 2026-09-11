//
//  SettingsCodingTests.swift
//  SharedSettingsTests
//
//  The shared JSON coder and Optional-payload flattening.
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("Settings coding", .serialized)
struct SettingsCodingTests {
	struct Stamp: Codable, Sendable, Equatable { let at: Date }
	struct StampKey: SettingsKey {
		static let defaultValue = Stamp(at: .distantPast)
		typealias Payload = Stamp
	}
	struct OptionalStampKey: SettingsKey {
		static var defaultValue: Stamp? { nil }
		typealias Payload = Stamp?
	}

	private func defaults() -> (UserDefaults, String) {
		let suiteName = "test.coding.\(UUID().uuidString)"
		return (UserDefaults(suiteName: suiteName)!, suiteName)
	}

	@Test("the iso8601 coding stores dates as ISO 8601 strings")
	func iso8601Dates() throws {
		let previous = SharedSettings.coding
		defer { SharedSettings.coding = previous }
		SharedSettings.coding = .iso8601
		let (store, suite) = defaults()
		defer { store.removePersistentDomain(forName: suite) }

		let stamp = Stamp(at: Date(timeIntervalSince1970: 1_700_000_000))
		StampKey.set(stamp, in: store)
		let raw = try #require(store.data(forKey: StampKey.name))
		#expect(String(decoding: raw, as: UTF8.self).contains("\"2023-11-14T22:13:20Z\""))
		#expect(StampKey.from(userDefaults: store) == stamp)
	}

	@Test("the default coding is unchanged: seconds since 2001")
	func foundationDefaultDates() throws {
		let (store, suite) = defaults()
		defer { store.removePersistentDomain(forName: suite) }
		StampKey.set(Stamp(at: Date(timeIntervalSinceReferenceDate: 12)), in: store)
		let raw = try #require(store.data(forKey: StampKey.name))
		#expect(String(decoding: raw, as: UTF8.self) == #"{"at":12}"#)
	}

	@Test("clearing an Optional payload removes the key instead of storing null")
	func clearedOptionalRemovesKey() {
		let (store, suite) = defaults()
		defer { store.removePersistentDomain(forName: suite) }
		OptionalStampKey.set(.some(Stamp(at: .now)), in: store)
		#expect(store.data(forKey: OptionalStampKey.name) != nil)
		OptionalStampKey.set(.some(nil), in: store)
		#expect(store.object(forKey: OptionalStampKey.name) == nil, "a cleared Optional is absent, not JSON null")
	}
}
