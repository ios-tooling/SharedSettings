import Testing
import Foundation
@testable import SharedSettingsMacros

@DeveloperSettings enum TestDevFlags {
	static var useStagingAPI: Bool = false
	static var animationSpeed: Double = 1
	static var serverName: String = "prod"
}

@UserSettings(.memory) enum TestUserPrefs {
	static var showTips: Bool = true
	static var refreshInterval: Int = 30
}

@BuildSettings enum TestBuild {
	static let apiBase = "https://api.example.com"
	static let logsNetworkTraffic = false
}

@DeveloperSettings public enum TestPublicFlags {   // public witnesses must compile
	public static var isEnabled: Bool = false
}

// These namespaces write to the standard defaults and the process-wide memory store, so the
// suite is serialized and each test cleans up after itself.
@Suite(.serialized) struct SettingsNamespaceTests {
	@Test func readsDeclaredDefaults() {
		#expect(TestDevFlags.useStagingAPI == false)
		#expect(TestDevFlags.animationSpeed == 1)
		#expect(TestUserPrefs.refreshInterval == 30)
	}

	@Test func roundTripsThroughTheGeneratedProperty() {
		defer { UserDefaults.standard.removeObject(forKey: "TestDevFlags.useStagingAPI") }

		TestDevFlags.useStagingAPI = true
		#expect(TestDevFlags.useStagingAPI == true)
		#expect(SharedSettings[TestDevFlags.UseStagingAPI.self] == true)
	}

	@Test func generatesAKeyTypePerSetting() {
		#expect(TestDevFlags.UseStagingAPI.kind == .developer)
		#expect(TestDevFlags.UseStagingAPI.location == .userDefaults)
		#expect(TestDevFlags.UseStagingAPI.name == "TestDevFlags.useStagingAPI")

		#expect(TestUserPrefs.ShowTips.kind == .user)
		#expect(TestUserPrefs.ShowTips.location == .memory)   // namespace-wide location
	}

	@Test func namespaceLocationAppliesToEveryMember() {
		defer { SharedSettings[TestUserPrefs.RefreshInterval.self] = 30 }

		TestUserPrefs.refreshInterval = 5
		#expect(TestUserPrefs.refreshInterval == 5)
		#expect(UserDefaults.standard.object(forKey: "TestUserPrefs.refreshInterval") == nil)
	}

	@Test func buildSettingsAreConstants() {
		#expect(TestBuild.apiBase == "https://api.example.com")
		#expect(TestBuild.logsNetworkTraffic == false)
		#expect(TestBuild.ApiBase.kind == .buildTime)
	}

	@Test func buildSettingsIgnoreWrites() {
		SharedSettings[TestBuild.ApiBase.self] = "https://evil.example.com"
		#expect(SharedSettings[TestBuild.ApiBase.self] == "https://api.example.com")
		#expect(TestBuild.apiBase == "https://api.example.com")
	}

	@Test func catalogsEverySettingInDeclarationOrder() {
		#expect(TestDevFlags.allSettings.map(\.id) == [
			"TestDevFlags.useStagingAPI",
			"TestDevFlags.animationSpeed",
			"TestDevFlags.serverName",
		])
		#expect(TestDevFlags.allSettings.allSatisfy { $0.kind == .developer })
	}

	@Test func derivesTitlesFromPropertyNames() {
		#expect(TestDevFlags.allSettings.map(\.title) == [
			"Use Staging API", "Animation Speed", "Server Name",
		])
		#expect(TestBuild.allSettings.map(\.title) == ["Api Base", "Logs Network Traffic"])
	}

	@Test func marksBuildSettingsAsNotEditable() {
		#expect(TestBuild.allSettings.allSatisfy { !$0.isEditable })
		#expect(TestDevFlags.allSettings.allSatisfy { $0.isEditable })
	}

	@Test @MainActor func entriesReadAndWriteTheLiveValue() {
		defer { SharedSettings[TestUserPrefs.ShowTips.self] = true }

		let entry = TestUserPrefs.allSettings[0]
		#expect(entry.value(as: Bool.self) == true)

		entry.binding(Bool.self, fallback: true).wrappedValue = false
		#expect(TestUserPrefs.showTips == false)
		#expect(entry.value(as: Bool.self) == false)
	}

	@Test @MainActor func entriesForBuildSettingsIgnoreWrites() {
		let entry = TestBuild.allSettings[0]
		entry.binding(String.self, fallback: "").wrappedValue = "https://evil.example.com"
		#expect(entry.value(as: String.self) == "https://api.example.com")
	}

	@Test @MainActor func settingWrapperObservesGeneratedKeys() {
		defer { SharedSettings[TestUserPrefs.ShowTips.self] = true }

		let wrapper = Setting(TestUserPrefs.ShowTips.self)
		#expect(wrapper.wrappedValue == true)

		wrapper.projectedValue.wrappedValue = false
		#expect(TestUserPrefs.showTips == false)
	}

	@Test func namespacesConformToSettingsNamespace() {
		let namespaces: [any SettingsNamespace.Type] = [TestDevFlags.self, TestBuild.self]
		let entries = namespaces.flatMap { $0.allSettings }
		#expect(entries.count == 5)
	}
}
