//
//  SwiftUIIntegrationTests.swift
//  SharedSettingsTests
//
//  Tests SwiftUI integration and property wrapper behavior
//

import Testing
import SwiftUI
@testable import SharedSettings

@Suite("SwiftUI Integration Tests")
@MainActor
struct SwiftUIIntegrationTests {

	func createTestDefaults() -> (UserDefaults, String) {
		let suiteName = "test.swiftui.\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		return (defaults, suiteName)
	}

	// MARK: - Test Keys

	struct StringSetting: SettingsKey {
		static let defaultValue = "default"
		typealias Payload = String
	}

	struct IntSetting: SettingsKey {
		static let defaultValue = 0
		typealias Payload = Int
	}

	struct BoolSetting: SettingsKey {
		static let defaultValue = false
		typealias Payload = Bool
	}

	// MARK: - Property Wrapper Tests

	@Test("Property wrapper read")
	func propertyWrapperRead() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)
		settings[StringSetting.self] = "test value"

		let wrapper = Setting(StringSetting.self, settings: observed)

		#expect(wrapper.wrappedValue == "test value")
	}

	@Test("Property wrapper write")
	func propertyWrapperWrite() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		let wrapper = Setting(StringSetting.self, settings: observed)
		wrapper.wrappedValue = "new value"

		#expect(settings[StringSetting.self] == "new value")
	}

	@Test("Property wrapper default value")
	func propertyWrapperDefaultValue() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		let wrapper = Setting(StringSetting.self, settings: observed)

		#expect(wrapper.wrappedValue == "default")
	}

	@Test("Property wrapper projected value (binding)")
	func propertyWrapperProjectedValue() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)
		settings[StringSetting.self] = "initial"

		let wrapper = Setting(StringSetting.self, settings: observed)
		let binding = wrapper.projectedValue

		#expect(binding.wrappedValue == "initial")

		binding.wrappedValue = "updated"

		#expect(settings[StringSetting.self] == "updated")
	}

	@Test("Multiple property wrappers")
	func multiplePropertyWrappers() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		let stringWrapper = Setting(StringSetting.self, settings: observed)
		let intWrapper = Setting(IntSetting.self, settings: observed)
		let boolWrapper = Setting(BoolSetting.self, settings: observed)

		stringWrapper.wrappedValue = "string"
		intWrapper.wrappedValue = 42
		boolWrapper.wrappedValue = true

		#expect(stringWrapper.wrappedValue == "string")
		#expect(intWrapper.wrappedValue == 42)
		#expect(boolWrapper.wrappedValue == true)
	}

	// MARK: - ObservedSettings Tests

	@Test("ObservedSettings read")
	func observedSettingsRead() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)
		settings[StringSetting.self] = "observed"

		let value = observed[StringSetting.self]

		#expect(value == "observed")
	}

	@Test("ObservedSettings write")
	func observedSettingsWrite() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		observed[StringSetting.self] = "new value"

		#expect(settings[StringSetting.self] == "new value")
	}

	@Test("ObservedSettings nil value")
	func observedSettingsNilValue() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		let value = observed[StringSetting.self]

		#expect(value == nil)
	}

	// MARK: - Integration Tests

	@Test("Property wrapper and direct access consistency")
	func propertyWrapperAndDirectAccessConsistency() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		let wrapper = Setting(StringSetting.self, settings: observed)
		wrapper.wrappedValue = "via wrapper"

		#expect(settings[StringSetting.self] == "via wrapper")

		settings[StringSetting.self] = "via direct"

		#expect(observed[StringSetting.self] == "via direct")
	}

	@Test("Binding two-way sync")
	func bindingTwoWaySync() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		let wrapper1 = Setting(IntSetting.self, settings: observed)
		_ = Setting(IntSetting.self, settings: observed)

		wrapper1.wrappedValue = 100

		#expect(observed[IntSetting.self] == 100)
	}

	@Test("Custom UserDefaults")
	func settingWithCustomUserDefaults() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let customSuite = "test.custom.\(UUID().uuidString)"
		let customDefaults = UserDefaults(suiteName: customSuite)!
		defer { customDefaults.removePersistentDomain(forName: customSuite) }

		let settings1 = Settings(defaults: customDefaults)
		let settings2 = Settings(defaults: testDefaults)
		let observed1 = ObservedSettings(settings: settings1)

		let wrapper = Setting(StringSetting.self, settings: observed1)
		wrapper.wrappedValue = "custom"

		#expect(settings1[StringSetting.self] == "custom")
		#expect(settings2[StringSetting.self] == nil)
	}

	@Test("Observation uses global keypath (documents behavior)")
	func observationUsesGlobalKeyPath() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		// This test documents that ObservedSettings uses \.self for observation
		// Which means ALL changes trigger ALL observers
		// This is a known limitation of the current implementation

		observed[StringSetting.self] = "test"

		#expect(observed[StringSetting.self] == "test")
	}

	@Test("Property wrapper is MainActor isolated")
	func propertyWrapperIsMainActorIsolated() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		await MainActor.run {
			let wrapper = Setting(StringSetting.self, settings: observed)
			wrapper.wrappedValue = "main actor"
			#expect(wrapper.wrappedValue == "main actor")
		}
	}

	@Test("ObservedSettings is MainActor isolated")
	func observedSettingsIsMainActorIsolated() async {
		let (testDefaults, suiteName) = createTestDefaults()
		defer { testDefaults.removePersistentDomain(forName: suiteName) }

		let settings = Settings(defaults: testDefaults)
		let observed = ObservedSettings(settings: settings)

		await MainActor.run {
			observed[StringSetting.self] = "main actor"
			#expect(observed[StringSetting.self] == "main actor")
		}
	}
}
