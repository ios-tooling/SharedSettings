import Testing
@testable import SharedSettingsMacros

@MemorySetting(false) struct MemFlag {}
@MemorySetting(0) struct MemCount {}
@MemorySetting("idle") struct MemDefault {}

// The `.memory` store is a process-global singleton, so each test uses its own
// dedicated key and the suite is serialized to avoid cross-test interference.
@Suite(.serialized) struct MemorySettingTests {
	@Test func unsetKeyReturnsDeclaredDefault() {
		#expect(SharedSettings[MemDefault.self] == "idle")
		#expect(MemDefault.location == .memory)
	}

	@Test func roundTripsThroughMemory() {
		SharedSettings[MemFlag.self] = true
		#expect(SharedSettings[MemFlag.self] == true)

		SharedSettings[MemCount.self] = 7
		#expect(SharedSettings[MemCount.self] == 7)
	}
}
