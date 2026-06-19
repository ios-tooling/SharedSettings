import Testing
@testable import SharedSettingsMacros

@MemorySetting(false) struct IsReady {}
@MemorySetting(0) struct LaunchCount {}

struct MemorySettingTests {
	@Test func defaultsToDeclaredValue() {
		SharedSettings[IsReady.self] = false
		#expect(SharedSettings[IsReady.self] == false)
		#expect(IsReady.location == .memory)
	}

	@Test func roundTripsThroughMemory() {
		SharedSettings[LaunchCount.self] = 7
		#expect(SharedSettings[LaunchCount.self] == 7)

		SharedSettings[IsReady.self] = true
		#expect(SharedSettings[IsReady.self] == true)
	}
}
