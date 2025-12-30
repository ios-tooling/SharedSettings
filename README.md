# SharedSettings

A type-safe, thread-safe, and SwiftUI-friendly wrapper around `UserDefaults` for iOS, macOS, tvOS, and watchOS.

## Features

- ✅ **Type-safe** - Compile-time type checking for all settings
- ✅ **Thread-safe** - Built with Swift 6 concurrency in mind
- ✅ **SwiftUI Integration** - Property wrappers and `@Observable` support
- ✅ **Flexible** - Supports all `UserDefaults` types plus `Codable` types
- ✅ **CloudKit Support** - Store settings in iCloud with `NSUbiquitousKeyValueStore`
- ✅ **Lightweight** - Minimal overhead over raw `UserDefaults`
- ✅ **Testable** - Instance-based design for easy testing
- ✅ **No Dependencies** - Pure Swift with no external dependencies

## Installation

### Swift Package Manager

Add SharedSettings to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ios-tooling/SharedSettings.git", from: "1.0.0")
]
```

Or add it via Xcode: File → Add Package Dependencies

## Quick Start

### 1. Define Your Settings Keys

```swift
import SharedSettings

struct ThemeKey: SettingsKey {
    static let defaultValue = "light"
}

struct NotificationsEnabledKey: SettingsKey {
    static let defaultValue = true
}

struct FontSizeKey: SettingsKey {
    static let defaultValue = 14
}
```

### 2. Read and Write Settings

```swift
// Using the global instance
let theme = Settings.instance[ThemeKey.self] ?? ThemeKey.defaultValue
Settings.instance[ThemeKey.self] = "dark"
```

### 3. SwiftUI Integration

```swift
import SwiftUI
import SharedSettings

struct SettingsView: View {
    @Setting(ThemeKey.self) var theme
    @Setting(NotificationsEnabledKey.self) var notificationsEnabled
    @Setting(FontSizeKey.self) var fontSize

    var body: some View {
        Form {
            Picker("Theme", selection: $theme) {
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }

            Toggle("Notifications", isOn: $notificationsEnabled)

            Stepper("Font Size: \(fontSize)", value: $fontSize, in: 10...24)
        }
    }
}
```

## Supported Types

SharedSettings supports all native `UserDefaults` types plus `Codable` types:

### Native UserDefaults Types

These are stored directly without encoding:

- `String`
- `Bool`
- `Int`
- `Double`
- `URL`
- `Data`
- `Date`
- `[String]` 

### Enums (via RawRepresentable)

String and Int-backed enums are stored using their raw values:

```swift
enum Theme: String, Codable, Sendable {
    case light, dark, auto
}

struct ThemeKey: SettingsKey {
    static let defaultValue = Theme.light
}

// Stored as "dark" (string) in UserDefaults
Settings.instance[ThemeKey.self] = .dark
```

### Codable Types

Any `Codable` type is automatically supported:

```swift
struct UserPreferences: Codable, Sendable, Equatable {
    let name: String
    let age: Int
    let favoriteColors: [String]
}

struct PreferencesKey: SettingsKey {
    static let defaultValue = UserPreferences(name: "", age: 0, favoriteColors: [])
}

let prefs = UserPreferences(name: "Alice", age: 30, favoriteColors: ["blue", "green"])
Settings.instance[PreferencesKey.self] = prefs
```

## Custom Key Names

By default, the key name is the type name. You can customize it:

```swift
struct MySettingKey: SettingsKey {
    static let defaultValue = ""
    static let name = "com.myapp.customKeyName"  // Custom key
}
```

## CloudKit Storage

SharedSettings supports storing settings in iCloud using `NSUbiquitousKeyValueStore`. This enables automatic syncing across a user's devices.

### Basic CloudKit Usage

To use CloudKit storage, set the `location` property to `.cloudKit`:

```swift
struct CloudSyncedThemeKey: SettingsKey {
    static let defaultValue = "light"
    static let location: SettingsLocation = .cloudKit  // Syncs via iCloud
}

// Use it exactly like UserDefaults-backed settings
Settings.instance[CloudSyncedThemeKey.self] = "dark"
let theme = Settings.instance[CloudSyncedThemeKey.self]
```

### Mixed Storage

You can use both UserDefaults and CloudKit storage in the same app:

```swift
// Local-only setting (not synced)
struct LocalCachePathKey: SettingsKey {
    static let defaultValue = ""
    static let location: SettingsLocation = .userDefaults  // Default
}

// Cloud-synced setting
struct UserPreferredLanguageKey: SettingsKey {
    static let defaultValue = "en"
    static let location: SettingsLocation = .cloudKit  // Syncs across devices
}

Settings.instance[LocalCachePathKey.self] = "/tmp/cache"  // Local only
Settings.instance[UserPreferredLanguageKey.self] = "es"   // Syncs to iCloud
```

### CloudKit Setup Requirements

To use CloudKit storage in your app:

1. **Enable iCloud capability** in your Xcode project
2. **Enable Key-Value Storage** in the iCloud settings
3. **Add CloudKit entitlements** to your app

```xml
<!-- Info.plist or entitlements -->
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
```

### Supported CloudKit Types

CloudKit storage supports the same types as UserDefaults:

- Primitives: `String`, `Bool`, `Int`, `Double`, `URL`, `Data`, `Date`, `[String]`
- String and Int-backed enums (via `RawRepresentable`)
- Any `Codable` type (JSON-encoded)

### CloudKit Limitations

Be aware of CloudKit's limits:

- **1 MB total storage** per app
- **1024 keys maximum**
- **1 KB per value** (except `Data` and arrays)
- Best for small user preferences, not large datasets

### SwiftUI with CloudKit

CloudKit-backed settings work seamlessly with SwiftUI:

```swift
struct SettingsView: View {
    @Setting(CloudSyncedThemeKey.self) var theme  // Syncs via iCloud

    var body: some View {
        Picker("Theme", selection: $theme) {
            Text("Light").tag("light")
            Text("Dark").tag("dark")
        }
    }
}
```

Changes made on one device will automatically sync to other devices signed into the same iCloud account.

## Advanced Usage

### Direct UserDefaults Access

You can also use the static methods on `SettingsKey` for direct access:

```swift
// Read
let theme = ThemeKey.from(userDefaults: .standard)

// Write
ThemeKey.set("dark", in: .standard)

// Remove
ThemeKey.set(nil, in: .standard)
```

### ObservedSettings for SwiftUI

For programmatic access to settings within SwiftUI views:

```swift
@MainActor
struct ContentView: View {
    let observed = ObservedSettings.instance

    var body: some View {
        Button("Toggle Theme") {
            let current = observed[ThemeKey.self] ?? "light"
            observed[ThemeKey.self] = current == "light" ? "dark" : "light"
        }
    }
}
```


## Thread Safety

SharedSettings is fully thread-safe and compatible with Swift 6 strict concurrency:

- `Settings` uses `OSAllocatedUnfairLock` for synchronized access
- All types conform to `Sendable`
- `ObservedSettings` and `Setting` are `@MainActor` isolated
- Safe for concurrent reads and writes from multiple threads

```swift
// Safe to call from any thread
Task.detached {
    Settings.instance[ThemeKey.self] = "dark"
}

Task.detached {
    let theme = Settings.instance[ThemeKey.self]
}
```

## Architecture

### SettingsKey Protocol

All settings keys must conform to `SettingsKey`:

```swift
public protocol SettingsKey<Payload>: Sendable {
    associatedtype Payload: Codable & Sendable

    /// The default value returned when the key doesn't exist
    static var defaultValue: Payload { get }

    /// The storage key name (defaults to type name)
    static var name: String { get }

    /// The storage location (defaults to .userDefaults)
    static var location: SettingsLocation { get }

    /// Read the value from UserDefaults
    nonisolated static func from(userDefaults: UserDefaults) -> Payload?

    /// Write the value to UserDefaults
    nonisolated static func set(_ value: Payload?, in userDefaults: UserDefaults)

    /// Read the value from CloudKit
    nonisolated static func fromCloudKit() -> Payload?

    /// Write the value to CloudKit
    nonisolated static func setInCloudKit(_ value: Payload?)
}
```

### Settings Class

The main settings container:

```swift
let settings = Settings.instance              // Shared singleton
```

### ObservedSettings (SwiftUI)

An `@Observable` wrapper for SwiftUI:

```swift
@MainActor @Observable
public class ObservedSettings {
    public static let instance: ObservedSettings
    public subscript<Key: SettingsKey>(_ key: Key.Type) -> Key.Payload?
}
```

### Setting Property Wrapper (SwiftUI)

A `@propertyWrapper` for SwiftUI views:

```swift
@propertyWrapper @MainActor
public struct Setting<Key: SettingsKey>: DynamicProperty {
    public init(_ key: Key.Type)
    public var wrappedValue: Key.Payload { get nonmutating set }
    public var projectedValue: Binding<Key.Payload> { get }
}
```

## Best Practices

1. **Define keys in a central location** - Keep all your `SettingsKey` types organized
2. **Use descriptive names** - Make key names clear and purposeful
3. **Group related settings** - Use nested structs or enums to organize keys
4. **Provide sensible defaults** - Always set a reasonable `defaultValue`
5. **Use the singleton for app settings** - `Settings.instance` for global app state
6. **Create instances for testing** - Use `Settings(defaults:)` in tests for isolation
7. **Leverage property wrappers in SwiftUI** - Use `@Setting` for automatic view updates

## Example: Organizing Settings

```swift
enum AppSettings {
    struct Theme: SettingsKey {
        static let defaultValue = "light"
    }

    enum Notifications {
        struct Enabled: SettingsKey {
            static let defaultValue = true
        }

        struct Sound: SettingsKey {
            static let defaultValue = "default"
        }
    }

	 struct Display {
        struct FontSize: SettingsKey {
            static let defaultValue = 14
        }

        struct ShowPreview: SettingsKey {
            static let defaultValue = true
        }
    }
}

// Usage
Settings.instance[AppSettings.Theme.self] = "dark"
Settings.instance[AppSettings.Notifications.Enabled.self] = true
Settings.instance[AppSettings.Display.FontSize.self] = 16
```

## Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+
- Swift 6.0+
- Xcode 16.0+

**Note:** CloudKit features require the same minimum versions and iCloud entitlements.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
