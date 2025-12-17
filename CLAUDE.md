# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SharedSettings is a Swift Package Manager (SPM) library that provides a type-safe, protocol-oriented wrapper around UserDefaults for SwiftUI applications. It leverages Swift 6.1+ features including the `@Observable` macro and strict concurrency checking.

**Platforms:** macOS 14+, iOS 17+, watchOS 10+

## Build Commands

```bash
# Build the package
swift build

# Build in release mode
swift build -c release

# Clean build artifacts
rm -rf .build
```

## Testing Commands

The package includes a comprehensive test suite using Swift Testing framework.

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run with thread sanitizer (recommended for concurrency testing)
swift test -Xswiftc -sanitize=thread

# Build and test
swift build && swift test
```

**Test Coverage:**
- 74 tests across 5 test suites
- Basic settings functionality
- Type-specific tests (all supported types)
- Thread safety and concurrent access
- Edge cases and error conditions
- SwiftUI integration (property wrappers, bindings, ObservedSettings)

All tests use instance-based `Settings` and `ObservedSettings` for complete isolation.

## Architecture

### Core Design Pattern

The framework uses a **layered protocol-oriented architecture** with four distinct layers:

1. **SettingsKey Protocol** (Type Definition Layer)
   - Protocol with associated types defining setting keys
   - Each conforming type specifies its `Payload` (must be Codable) and `defaultValue`
   - Customizable `name` property for UserDefaults key naming
   - Protocol extensions in `Settings+UserDefaults.swift` provide type-specific implementations

2. **Settings Class** (Storage Layer)
   - Singleton (`Settings.instance`) for global access or instance-based (`Settings(defaults:)`) for isolation
   - Thread-safe using `OSAllocatedUnfairLock<UserDefaults?>` (properly Sendable)
   - Generic subscript `subscript<Key: SettingsKey>(_: Key.Type) -> Key.Payload?`
   - Supports custom UserDefaults instances via `init(defaults: UserDefaults)`
   - Can swap UserDefaults at runtime with `set(userDefaults:)` method

3. **ObservedSettings Class** (Observation Layer)
   - `@Observable` wrapper around Settings for SwiftUI reactivity
   - MainActor-isolated singleton (`ObservedSettings.instance`) or instance-based (`ObservedSettings(settings:)`)
   - Provides observation hooks (`access`/`withMutation`) for Swift's observation system
   - Separate from Settings to allow non-UI usage without observation overhead

4. **@Setting Property Wrapper** (SwiftUI Integration Layer)
   - Convenient property wrapper conforming to `DynamicProperty`
   - Provides `wrappedValue` for direct access and `projectedValue` for SwiftUI Bindings
   - Can use global instance `Setting(Key.self)` or custom `Setting(Key.self, settings: observed)`
   - MainActor-isolated for UI safety

### Type Specialization Strategy

`Settings+UserDefaults.swift` uses protocol extensions with type constraints to provide optimized implementations:

- **Direct storage** for primitives (String, Bool, Int, URL, Data, [String])
- **JSON encoding** fallback for any Codable type
- **Optional handling** via OptionalBox protocol

This prevents unnecessary encoding overhead for simple types while supporting arbitrary Codable types.

### Concurrency Model

- **Settings**: `nonisolated final class` with proper `Sendable` conformance (no `@unchecked`)
  - Uses `OSAllocatedUnfairLock<UserDefaults?>` for thread-safe access
  - UserDefaults is retroactively marked as `@unchecked Sendable` (documented as thread-safe by Apple)
- **ObservedSettings**: `@MainActor @Observable` for UI observation
- **@Setting wrapper**: `@MainActor` isolated as a `DynamicProperty`
- **SettingsKey protocol**: Requires `Sendable` conformance with `Payload: Codable & Sendable`
- Fully compatible with Swift 6 strict concurrency checking
- All concurrent access is protected by the lock in Settings

## Key Implementation Notes

### Adding New Setting Keys

Define a type conforming to `SettingsKey`:

```swift
struct MyCustomSetting: SettingsKey {
    static let defaultValue = "default"
    typealias Payload = String
    // Optional: customize key name
    static let name = "custom_key_name"
}
```

The protocol extension in `Settings+UserDefaults.swift` automatically handles Codable types. For optimal performance with custom types, consider adding specialized extensions for non-Codable types.

### Custom UserDefaults Support

Both Settings and ObservedSettings accept custom UserDefaults instances:

```swift
// App groups
let groupDefaults = UserDefaults(suiteName: "group.com.example.app")!
let settings = Settings(defaults: groupDefaults)

// Testing with isolated instance
let testDefaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
let settings = Settings(defaults: testDefaults)
```

### SwiftUI Usage Patterns

```swift
// Using global singleton (most common)
@Setting(MyCustomSetting.self) var mySetting
// Direct access: mySetting
// Binding: $mySetting

// Using custom instance (for testing or isolation)
let settings = Settings(defaults: customDefaults)
let observed = ObservedSettings(settings: settings)
let wrapper = Setting(MyCustomSetting.self, settings: observed)
```

### Testing Pattern

Tests use isolated instances to avoid shared state:

```swift
@Test("My test")
func myTest() {
    let testDefaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
    defer { testDefaults.removePersistentDomain(forName: suiteName) }

    let settings = Settings(defaults: testDefaults)
    settings[MyKey.self] = "value"

    #expect(settings[MyKey.self] == "value")
}
```

This pattern ensures:
- Complete test isolation (no shared state)
- Tests can run in parallel
- No cleanup of global singleton required

## File Organization

### Sources/SharedSettings/
- `SettingsKey.swift` - Protocol definition with default `name` implementation
- `SettingsKey+UserDefaults.swift` - Type-specific implementations for all supported types
- `Settings.swift` - Core storage logic with thread-safe lock
- `ObservedSettings.swift` - SwiftUI observation wrapper (`@Observable`)
- `SettingsWrapper.swift` - `@Setting` property wrapper for SwiftUI

### Tests/SharedSettingsTests/
- `BasicSettingsTests.swift` - Core CRUD operations (8 tests)
- `TypeSpecificTests.swift` - All supported types: String, Bool, Int, Double, URL, Data, Date, Arrays, Enums, Codable (30 tests)
- `ThreadSafetyTests.swift` - Concurrent access, data races, lock verification (7 tests)
- `EdgeCaseTests.swift` - Error handling, corrupt data, nil vs default values (16 tests)
- `SwiftUIIntegrationTests.swift` - Property wrappers, bindings, ObservedSettings, MainActor isolation (13 tests)

All test files use Swift Testing framework with `@Suite`, `@Test`, and `#expect` macros.
