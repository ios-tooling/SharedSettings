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

Note: This package currently has no test target defined in Package.swift. Tests would need to be added to the package manifest first.

```bash
# Run all tests (when tests are added)
swift test

# Run with verbose output
swift test --verbose

# Run specific test by filter
swift test --filter <test-target>.<test-case>

# Skip specific tests
swift test --skip <pattern>
```

## Architecture

### Core Design Pattern

The framework uses a **layered protocol-oriented architecture** with four distinct layers:

1. **SettingsKey Protocol** (Type Definition Layer)
   - Protocol with associated types defining setting keys
   - Each conforming type specifies its `Payload` (must be Codable) and `defaultValue`
   - Customizable `name` property for UserDefaults key naming
   - Protocol extensions in `Settings+UserDefaults.swift` provide type-specific implementations

2. **Settings Class** (Storage Layer)
   - Singleton (`Settings.instance`) managing UserDefaults access
   - Thread-safe with `@unchecked Sendable` conformance
   - Generic subscript `subscript<Key: SettingsKey>(_: Key.Type) -> Key.Payload`
   - Supports custom UserDefaults instances for app groups

3. **ObservedSettings Class** (Observation Layer)
   - `@Observable` wrapper around Settings for SwiftUI reactivity
   - MainActor-isolated singleton (`ObservedSettings.instance`)
   - Provides observation hooks (`access`/`withMutation`) for Swift's observation system
   - Separate from Settings to allow non-UI usage without observation overhead

4. **@Setting Property Wrapper** (SwiftUI Integration Layer)
   - Convenient property wrapper conforming to `DynamicProperty`
   - Provides `wrappedValue` for direct access and `projectedValue` for SwiftUI Bindings
   - MainActor-isolated for UI safety

### Type Specialization Strategy

`Settings+UserDefaults.swift` uses protocol extensions with type constraints to provide optimized implementations:

- **Direct storage** for primitives (String, Bool, Int, URL, Data, [String])
- **JSON encoding** fallback for any Codable type
- **Optional handling** via OptionalBox protocol

This prevents unnecessary encoding overhead for simple types while supporting arbitrary Codable types.

### Concurrency Model

- **Settings**: Nonisolated access, `@unchecked Sendable` (UserDefaults is thread-safe)
- **ObservedSettings**: MainActor-isolated for UI observation
- **@Setting wrapper**: MainActor-isolated as a DynamicProperty
- Designed for Swift 6 strict concurrency checking

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
let groupDefaults = UserDefaults(suiteName: "group.com.example.app")!
let settings = Settings(userDefaults: groupDefaults)
```

### SwiftUI Usage Pattern

```swift
@Setting(MyCustomSetting.self) var mySetting
// Direct access: mySetting
// Binding: $mySetting
```

## File Organization

- `SettingsKey.swift` - Protocol definition
- `Settings.swift` - Core storage logic
- `Settings+UserDefaults.swift` - Type-specific implementations
- `ObservedSettings.swift` - SwiftUI observation wrapper
- `SettingsWrapper.swift` - @Setting property wrapper
- `OptionalBox.swift` - Optional type helper protocol
