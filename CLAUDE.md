# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SharedSettings is a Swift Package Manager (SPM) library that provides a type-safe, protocol-oriented wrapper around UserDefaults, CloudKit (NSUbiquitousKeyValueStore), and Keychain for SwiftUI applications. It leverages Swift 6.1+ features including the `@Observable` macro and strict concurrency checking.

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
   - Each conforming type specifies its `Payload` (must be Codable), `defaultValue`, and `location` (.userDefaults, .cloudKit, or .keychain)
   - Customizable `name` property for storage key naming
   - Protocol extensions in `SettingsKey+UserDefaults.swift`, `SettingsKey+CloudKit.swift`, and `SettingsKey+Keychain.swift` provide type-specific implementations
   - Supports UserDefaults, CloudKit, and Keychain storage backends

2. **SharedSettings Class** (Storage Layer)
   - Singleton (`SharedSettings.instance`) for global access or instance-based (`SharedSettings(defaults:)`) for isolation
   - Thread-safe using `OSAllocatedUnfairLock<UserDefaults?>` (properly Sendable)
   - Generic subscript `subscript<Key: SettingsKey>(_: Key.Type) -> Key.Payload?`
   - Routes to UserDefaults, CloudKit, or Keychain based on `Key.location`
   - Supports custom UserDefaults instances via `init(defaults: UserDefaults)`
   - Can swap UserDefaults at runtime with `set(userDefaults:)` method

3. **ObservedSettings Class** (Observation Layer)
   - `@Observable` wrapper around SharedSettings for SwiftUI reactivity
   - MainActor-isolated singleton (`ObservedSettings.instance`) or instance-based (`ObservedSettings(settings:)`)
   - Provides observation hooks (`access`/`withMutation`) for Swift's observation system
   - Separate from SharedSettings to allow non-UI usage without observation overhead

4. **@Setting Property Wrapper** (SwiftUI Integration Layer)
   - Convenient property wrapper conforming to `DynamicProperty`
   - Provides `wrappedValue` for direct access and `projectedValue` for SwiftUI Bindings
   - Can use global instance `Setting(Key.self)` or custom `Setting(Key.self, settings: observed)`
   - MainActor-isolated for UI safety

### Type Specialization Strategy

`SettingsKey+UserDefaults.swift`, `SettingsKey+CloudKit.swift`, and `SettingsKey+Keychain.swift` use protocol extensions with type constraints to provide optimized implementations:

- **Direct storage** for primitives (String, Bool, Int, Double, URL, Data, Date, [String])
- **RawRepresentable** support for enums (String-backed and Int-backed)
- **JSON encoding** fallback for any Codable type

This prevents unnecessary encoding overhead for simple types while supporting arbitrary Codable types. The same implementation strategy is mirrored across all three storage backends (UserDefaults, CloudKit, and Keychain).

### Concurrency Model

- **SharedSettings**: `nonisolated final class` with proper `Sendable` conformance (no `@unchecked`)
  - Uses `OSAllocatedUnfairLock<UserDefaults?>` for thread-safe access to UserDefaults
  - UserDefaults is retroactively marked as `@unchecked Sendable` (documented as thread-safe by Apple)
  - CloudKit access via `NSUbiquitousKeyValueStore.default` (thread-safe per Apple docs)
  - Keychain access via Security framework APIs (thread-safe per Apple docs)
- **ObservedSettings**: `@MainActor @Observable` for UI observation
- **@Setting wrapper**: `@MainActor` isolated as a `DynamicProperty`
- **SettingsKey protocol**: Requires `Sendable` conformance with `Payload: Codable & Sendable`
- Fully compatible with Swift 6 strict concurrency checking
- All concurrent access is protected by the lock (UserDefaults) or inherent thread safety (CloudKit, Keychain)

## Key Implementation Notes

### Adding New Setting Keys

Define a type conforming to `SettingsKey`:

```swift
// UserDefaults-backed setting (default)
struct MyCustomSetting: SettingsKey {
    static let defaultValue = "default"
    typealias Payload = String
    // Optional: customize key name
    static let name = "custom_key_name"
}

// CloudKit-backed setting (syncs across devices)
struct CloudSyncedSetting: SettingsKey {
    static let defaultValue = "default"
    typealias Payload = String
    static let location: SettingsLocation = .cloudKit
}

// Keychain-backed setting (secure storage for sensitive data)
struct APITokenKey: SettingsKey {
    static let defaultValue = ""
    typealias Payload = String
    static let location: SettingsLocation = .keychain
}
```

The protocol extensions in `SettingsKey+UserDefaults.swift`, `SettingsKey+CloudKit.swift`, and `SettingsKey+Keychain.swift` automatically handle all Codable types. Specialized extensions exist for primitives, RawRepresentable enums, and common types for optimal performance.

### Custom UserDefaults Support

Both SharedSettings and ObservedSettings accept custom UserDefaults instances:

```swift
// App groups
let groupDefaults = UserDefaults(suiteName: "group.com.example.app")!
let settings = SharedSettings(defaults: groupDefaults)

// Testing with isolated instance
let testDefaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
let settings = SharedSettings(defaults: testDefaults)
```

### CloudKit Storage

Settings can be stored in CloudKit (NSUbiquitousKeyValueStore) for automatic syncing across devices:

```swift
struct SyncedTheme: SettingsKey {
    static let defaultValue = "light"
    static let location: SettingsLocation = .cloudKit
}

// Access like any other setting
SharedSettings.instance[SyncedTheme.self] = "dark"
```

**CloudKit Limitations:**
- 1 MB total storage per app
- 1024 keys maximum
- 1 KB per value (except Data and arrays)
- Requires iCloud entitlements in your app

CloudKit-backed settings work seamlessly with all SwiftUI property wrappers and ObservedSettings.

### Keychain Storage

Settings can be stored in the Keychain for secure storage of sensitive data like passwords, API tokens, and credentials:

```swift
struct APITokenKey: SettingsKey {
    static let defaultValue = ""
    static let location: SettingsLocation = .keychain
}

struct CredentialsKey: SettingsKey {
    struct Credentials: Codable, Sendable {
        let username: String
        let password: String
    }
    static let defaultValue = Credentials(username: "", password: "")
    static let location: SettingsLocation = .keychain
}

// Access like any other setting
SharedSettings.instance[APITokenKey.self] = "secret_token_123"
```

**Keychain Implementation Details:**
- **Service name**: Derived from `Bundle.main.bundleIdentifier` (falls back to "SharedSettings")
- **Accessibility**: `kSecAttrAccessibleAfterFirstUnlock` (balanced security and availability)
- **Error handling**: Silently returns `nil` on Keychain access failures (matches UserDefaults/CloudKit behavior)
- **Item class**: `kSecClassGenericPassword` for all stored items

**Security Considerations:**
- Keychain items persist even after app deletion (until device reset or manual deletion)
- Items are encrypted and protected by the iOS/macOS security system
- Use Keychain for sensitive data; use UserDefaults for non-sensitive app preferences
- Keychain is ideal for: API tokens, passwords, encryption keys, authentication credentials

**Supported Types:**
All types supported by UserDefaults and CloudKit are also supported in Keychain:
- Primitives, enums, arrays, and custom Codable types
- All types are converted to Data for Keychain storage

Keychain-backed settings work seamlessly with all SwiftUI property wrappers and ObservedSettings.

### SwiftUI Usage Patterns

```swift
// Using global singleton (most common)
@Setting(MyCustomSetting.self) var mySetting
// Direct access: mySetting
// Binding: $mySetting

// Using custom instance (for testing or isolation)
let settings = SharedSettings(defaults: customDefaults)
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

    let settings = SharedSettings(defaults: testDefaults)
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
- `SettingsKey.swift` - Protocol definition with default `name` and `location` implementations
- `SettingsKey+UserDefaults.swift` - Type-specific UserDefaults implementations for all supported types
- `SettingsKey+CloudKit.swift` - Type-specific CloudKit implementations for all supported types
- `SettingsKey+Keychain.swift` - Type-specific Keychain implementations for all supported types
- `SharedSettings.swift` - Core storage logic with thread-safe lock and routing to UserDefaults/CloudKit/Keychain
- `ObservedSettings.swift` - SwiftUI observation wrapper (`@Observable`)
- `SettingsWrapper.swift` - `@Setting` property wrapper for SwiftUI

### Tests/SharedSettingsTests/
- `BasicSettingsTests.swift` - Core CRUD operations (8 tests)
- `TypeSpecificTests.swift` - All supported types: String, Bool, Int, Double, URL, Data, Date, Arrays, Enums, Codable (30 tests)
- `ThreadSafetyTests.swift` - Concurrent access, data races, lock verification (7 tests)
- `EdgeCaseTests.swift` - Error handling, corrupt data, nil vs default values (16 tests)
- `SwiftUIIntegrationTests.swift` - Property wrappers, bindings, ObservedSettings, MainActor isolation (13 tests)
- `KeychainTests.swift` - Keychain storage for all types, CRUD operations, persistence (15 tests)

All test files use Swift Testing framework with `@Suite`, `@Test`, and `#expect` macros.
