import Testing
import Foundation
@testable import SharedSettings

private struct PlainKey: SettingsKey {
	static let defaultValue = "plain"
}

private struct BakedInKey: SettingsKey {
	static let defaultValue = "https://api.example.com"
	static let kind: SettingsKind = .buildTime
}

private struct DevFlagKey: SettingsKey {
	static let defaultValue = false
	static let kind: SettingsKind = .developer
	static let location: SettingsLocation = .memory
}

@Suite(.serialized) struct SettingsKindTests {
	@Test func keysAreUserSettingsByDefault() {
		#expect(PlainKey.kind == .user)
	}

	@Test func buildTimeKeysAlwaysReadTheirDefault() {
		let settings = SharedSettings(defaults: UserDefaults.standard)
		#expect(settings[BakedInKey.self] == "https://api.example.com")
	}

	@Test func buildTimeKeysIgnoreWrites() {
		let suiteName = "test.\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		defer { defaults.removePersistentDomain(forName: suiteName) }

		let settings = SharedSettings(defaults: defaults)
		settings[BakedInKey.self] = "https://staging.example.com"

		#expect(settings[BakedInKey.self] == "https://api.example.com")
		#expect(defaults.object(forKey: BakedInKey.name) == nil)   // nothing was stored
	}

	@Test func developerKeysReadAndWriteNormallyWhateverTheBuild() {
		defer { SharedSettings.isDeveloperBuild = true }

		SharedSettings.isDeveloperBuild = false
		SharedSettings[DevFlagKey.self] = true
		#expect(SharedSettings[DevFlagKey.self] == true)   // the kind gates UI, not storage

		SharedSettings[DevFlagKey.self] = false
	}

	@Test func developerBuildFlagDefaultsToTheBuildConfiguration() {
		#if DEBUG
			#expect(SharedSettings.isDeveloperBuild == true)
		#else
			#expect(SharedSettings.isDeveloperBuild == false)
		#endif
	}

	@Test @MainActor func entriesEraseTheirKey() {
		let entry = DevFlagKey.entry(title: "Dev Flag")
		#expect(entry.id == "DevFlagKey")
		#expect(entry.kind == .developer)
		#expect(entry.isEditable)
		#expect(entry.value(as: Bool.self) == false)
	}
}
