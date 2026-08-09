//
//  AppGroupTests.swift
//  SharedSettingsTests
//
//  Tests App Group suite adoption and standard-defaults migration
//

import Testing
import Foundation
@testable import SharedSettings

@Suite("App Group Integration")
struct AppGroupTests {

	struct MigratedSetting: SettingsKey {
		static let defaultValue = "default"
		typealias Payload = String
	}

	// Adopting an App Group must route subsequent reads and writes through
	// the suite, not the process's standard defaults.
	@Test func adoptingGroupSwitchesStore() throws {
		let suiteName = "test.appgroup.\(UUID().uuidString)"
		defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

		let settings = SharedSettings()
		#expect(settings.use(appGroup: suiteName) == true)
		settings[MigratedSetting.self] = "written"

		let suite = try #require(UserDefaults(suiteName: suiteName))
		#expect(suite.string(forKey: MigratedSetting.name) == "written")
	}

	// Migration exists so an app that adopts an App Group after shipping
	// doesn't lose values earlier builds wrote to standard defaults.
	@Test func migrationCopiesLegacyValuesOnce() throws {
		let suiteName = "test.appgroup.\(UUID().uuidString)"
		defer {
			UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
			UserDefaults.standard.removeObject(forKey: MigratedSetting.name)
		}

		UserDefaults.standard.set("legacy", forKey: MigratedSetting.name)
		let settings = SharedSettings()
		settings.use(appGroup: suiteName, migrating: [MigratedSetting.self])
		#expect(settings[MigratedSetting.self] == "legacy")

		// A value already in the suite must win over the standard-defaults one.
		let suite = try #require(UserDefaults(suiteName: suiteName))
		suite.set("suite-value", forKey: MigratedSetting.name)
		UserDefaults.standard.set("legacy-2", forKey: MigratedSetting.name)
		let second = SharedSettings()
		second.use(appGroup: suiteName, migrating: [MigratedSetting.self])
		#expect(second[MigratedSetting.self] == "suite-value")
	}
}
