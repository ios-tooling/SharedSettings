# SharedSettings

A type-safe, thread-safe, SwiftUI-friendly settings library for Apple platforms. Wraps `UserDefaults`, `NSUbiquitousKeyValueStore` (CloudKit), and Keychain behind a unified, protocol-oriented API.

**Platforms:** macOS 14+, iOS 17+, tvOS 17+, visionOS 1+, watchOS 10+
**Requirements:** Swift 6.1+, Xcode 16+

## Features

- **Type-safe** — compile-time type checking for all settings
- **Three backends** — UserDefaults, CloudKit (iCloud sync), and Keychain (secure storage)
- **Three kinds** — user, developer, and build-time settings, one line of code each
- **Swift 6 concurrency** — `Sendable`, `OSAllocatedUnfairLock`, no `@unchecked` hacks
- **SwiftUI-native** — `@Setting` property wrapper, `@Observable` `ObservedSettings`, `Binding` support
- **Fully testable** — instance-based design for isolated tests
- **Zero dependencies** — pure Swift, no external packages

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ios-tooling/SharedSettings.git", from: "1.0.0")
]
```

Or via Xcode: **File → Add Package Dependencies**

---

## Core Concepts

### SettingsKey Protocol

Every setting is a type conforming to `SettingsKey`:

```swift
public protocol SettingsKey<Payload>: Sendable {
    associatedtype Payload: Codable & Sendable

    static var defaultValue: Payload { get }       // Returned when key is absent
    static var name: String { get }                // Storage key (defaults to type name)
    static var location: SettingsLocation { get }  // .userDefaults | .cloudKit | .keychain
    static var kind: SettingsKind { get }          // .user | .developer | .buildTime
}
```

Most keys never mention `kind` — see [Settings Kinds](#settings-kinds), where the macros declare it for you.

### SettingsLocation

```swift
public enum SettingsLocation {
    case userDefaults   // Local, persistent (default)
    case cloudKit       // iCloud-synced via NSUbiquitousKeyValueStore
    case keychain       // Secure, encrypted, persists across reinstalls
}
```

### SharedSettings

Thread-safe storage class. Use the singleton or create isolated instances:

```swift
SharedSettings.instance          // Global singleton
SharedSettings(defaults:)        // Custom UserDefaults (e.g. App Groups, testing)
```

Subscript API:

```swift
SharedSettings.instance[ThemeKey.self]          // -> Key.Payload? (nil if unset)
SharedSettings.instance[ThemeKey.self] = "dark"  // write
SharedSettings.instance[ThemeKey.self] = nil     // remove
```

### ObservedSettings

`@MainActor @Observable` wrapper around `SharedSettings` for SwiftUI reactivity:

```swift
ObservedSettings.instance           // Global singleton, MainActor
ObservedSettings(settings:)         // Custom instance for testing
```

### @Setting Property Wrapper

`DynamicProperty` for SwiftUI views. Returns `defaultValue` when the key is unset (never optional):

```swift
@Setting(ThemeKey.self) var theme           // wrappedValue: Key.Payload
$theme                                      // projectedValue: Binding<Key.Payload>
```

---

## Quick Start

### 1. Define Keys

```swift
import SharedSettings

// UserDefaults (default)
struct ThemeKey: SettingsKey {
    static let defaultValue = "light"
}

// CloudKit — syncs across devices
struct LanguageKey: SettingsKey {
    static let defaultValue = "en"
    static let location: SettingsLocation = .cloudKit
}

// Keychain — encrypted, persists after uninstall
struct APITokenKey: SettingsKey {
    static let defaultValue = ""
    static let location: SettingsLocation = .keychain
}
```

### 2. Read and Write

```swift
// Read (returns optional — nil means unset, use ?? defaultValue or @Setting)
let theme = SharedSettings.instance[ThemeKey.self] ?? ThemeKey.defaultValue

// Write
SharedSettings.instance[ThemeKey.self] = "dark"
SharedSettings.instance[APITokenKey.self] = "secret_token_123"

// Remove
SharedSettings.instance[ThemeKey.self] = nil
```

### 3. SwiftUI Integration

```swift
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

---

## Supported Types

All three backends support the same types:

| Category | Types |
|----------|-------|
| Primitives | `String`, `Bool`, `Int`, `Double`, `URL`, `Data`, `Date`, `[String]` |
| Enums | `String`- and `Int`-backed `RawRepresentable` |
| Custom | Any `Codable & Sendable` type (JSON-encoded) |

Primitives are stored natively (no encoding overhead). Enums use their raw value. Custom types use `JSONEncoder`/`JSONDecoder`.

### Enum Example

```swift
enum Theme: String, Codable, Sendable { case light, dark, auto }

struct ThemeKey: SettingsKey {
    static let defaultValue = Theme.light
}

SharedSettings.instance[ThemeKey.self] = .dark  // stored as "dark"
```

### Custom Codable Example

```swift
struct UserPreferences: Codable, Sendable {
    let name: String
    let fontSize: Int
}

struct PreferencesKey: SettingsKey {
    static let defaultValue = UserPreferences(name: "", fontSize: 14)
}

SharedSettings.instance[PreferencesKey.self] = UserPreferences(name: "Alice", fontSize: 16)
```

---

## Storage Backends

### UserDefaults (default)

Standard local preferences. The default when `location` is omitted.

```swift
struct CachePathKey: SettingsKey {
    static let defaultValue = ""
    // static let location: SettingsLocation = .userDefaults  // implicit default
}
```

**App Groups:**

```swift
let groupDefaults = UserDefaults(suiteName: "group.com.example.app")!
let settings = SharedSettings(defaults: groupDefaults)
```

### CloudKit

Syncs automatically across the user's devices via `NSUbiquitousKeyValueStore`.

```swift
struct SyncedThemeKey: SettingsKey {
    static let defaultValue = "light"
    static let location: SettingsLocation = .cloudKit
}
```

**Setup requirements:**
1. Enable iCloud capability in Xcode
2. Enable Key-Value Storage under iCloud settings
3. Add entitlement:

```xml
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
```

**Limits:** 1 MB total, 1024 keys, 1 KB per value (except `Data` and arrays)

### Keychain

Encrypted storage for sensitive data. Items persist across app reinstalls.

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
```

**Implementation details:**
- Item class: `kSecClassGenericPassword`
- Service name: `Bundle.main.bundleIdentifier` (fallback: `"SharedSettings"`)
- Accessibility: `kSecAttrAccessibleAfterFirstUnlock`
- All types converted to `Data` for storage
- Access failures return `nil` (consistent with other backends)

**Use Keychain for:** API tokens, passwords, encryption keys, auth credentials
**Use UserDefaults for:** non-sensitive preferences, UI state, feature flags

---

## Custom Key Names

The default storage key is the type name. Override with `name`:

```swift
struct LegacySettingKey: SettingsKey {
    static let defaultValue = ""
    static let name = "com.myapp.legacy_preference_key"
}
```

---

## Organizing Keys

```swift
enum AppSettings {
    struct Theme: SettingsKey {
        static let defaultValue = "light"
    }

    enum Notifications {
        struct Enabled: SettingsKey { static let defaultValue = true }
        struct Sound: SettingsKey { static let defaultValue = "default" }
    }

    enum Sync {
        struct Language: SettingsKey {
            static let defaultValue = "en"
            static let location: SettingsLocation = .cloudKit
        }
    }

    enum Secure {
        struct APIToken: SettingsKey {
            static let defaultValue = ""
            static let location: SettingsLocation = .keychain
        }
    }
}

// Usage
SharedSettings.instance[AppSettings.Theme.self] = "dark"
SharedSettings.instance[AppSettings.Sync.Language.self] = "es"
SharedSettings.instance[AppSettings.Secure.APIToken.self] = token
```

---

## Settings Kinds

`SettingsLocation` says *where* a setting lives; `SettingsKind` says *who it's for*. The three
kinds each get a macro that turns one line into a full `SettingsKey`.

```swift
import SharedSettingsMacros
```

| Kind | Macro | Purpose |
|---|---|---|
| `.user` | `@UserSettings` | Preferences every user can change |
| `.developer` | `@DeveloperSettings` | Test flags, shown only in developer builds |
| `.buildTime` | `@BuildSettings` | Constants baked in at compile time |

### Declaring settings

```swift
@UserSettings enum AppSettings {
    static var showTips: Bool = true
    static var refreshInterval: Double = 30
}

@DeveloperSettings enum DevFlags {
    static var useStagingAPI: Bool = false
    static var animationSpeed: Double = 1
}

@BuildSettings enum Build {
    static let apiBase = "https://api.example.com"
    static let logsNetworkTraffic = false
}
```

Read and write them like plain properties, from anywhere:

```swift
AppSettings.showTips = false      // persisted to UserDefaults
DevFlags.useStagingAPI           // false unless a tester flipped it
Build.apiBase                    // read-only constant, no storage consulted
```

Each member also generates a `SettingsKey` named by capitalizing the property, so the usual API
— including SwiftUI observation — still works:

```swift
@Setting(AppSettings.ShowTips.self) var showTips   // observable in a view; $showTips is a Binding
SharedSettings[DevFlags.UseStagingAPI.self] = true
```

> The generated `AppSettings.showTips` property reads through `SharedSettings` and is *not*
> observed by SwiftUI. Inside a `View`, use `@Setting(AppSettings.ShowTips.self)`.

Two rules the macros enforce with a clear compiler error:

- `@UserSettings` / `@DeveloperSettings` members are `var` **with an explicit type** — the macro
  rewrites them into computed properties, so the type can't be inferred from the initializer.
- `@BuildSettings` members are `let` — they're constants, and stay exactly what you wrote.

### Storage location

Namespaces default to `.userDefaults`; pass a location to change it for every member:

```swift
@DeveloperSettings(.memory) enum SessionFlags {   // reset on every launch
    static var pretendOffline: Bool = false
}

@UserSettings(.cloudKit) enum SyncedPrefs {
    static var theme: String = "light"
}
```

Build settings ignore location entirely — reads always return the declared constant and writes
are no-ops, so a stale stored value can never survive a rebuild.

### The developer settings screen

Each namespace exposes `allSettings`, a catalog of type-erased `SettingsEntry` values, and
`DeveloperSettingsScreen` renders it — toggles for `Bool`, text fields for `String`/`Int`/`Double`,
read-only rows for build settings and other payloads:

```swift
NavigationLink("Developer") {
    DeveloperSettingsScreen(DevFlags.self, Build.self)
}
```

Pass namespaces explicitly (Swift can't discover conforming types at runtime), or build your own
UI from `DevFlags.allSettings`.

### Gating developer builds

```swift
SharedSettings.isDeveloperBuild = true
```

Defaults to `true` in DEBUG builds, `false` otherwise. `DeveloperSettingsScreen` self-gates on it,
so a debug menu left unhidden in a shipping build still shows nothing. Set it at launch to open
developer settings up in a TestFlight build, or flip it behind a hidden gesture.

It deliberately does **not** affect reads or writes — a `.developer` setting behaves identically in
every build, so a value a tester set keeps working and there's no second code path to test.

---

## Thread Safety

`SharedSettings` is `nonisolated` and `Sendable`:

- UserDefaults access protected by `OSAllocatedUnfairLock`
- `NSUbiquitousKeyValueStore` and Keychain are thread-safe per Apple docs
- `ObservedSettings` and `@Setting` are `@MainActor`-isolated

```swift
// Safe from any thread or Task
Task.detached { SharedSettings.instance[ThemeKey.self] = "dark" }
Task.detached { let theme = SharedSettings.instance[ThemeKey.self] }
```

---

## Testing

Use isolated `SharedSettings` instances to avoid shared state between tests:

```swift
@Test("stores and retrieves theme")
func storesTheme() {
    let suiteName = "test.\(UUID().uuidString)"
    let testDefaults = UserDefaults(suiteName: suiteName)!
    defer { testDefaults.removePersistentDomain(forName: suiteName) }

    let settings = SharedSettings(defaults: testDefaults)
    settings[ThemeKey.self] = "dark"

    #expect(settings[ThemeKey.self] == "dark")
}
```

This pattern gives full isolation, supports parallel test execution, and requires no global state cleanup.

---

## SecureURLStore

`SecureURLStore` is a small companion type for persisting **security-scoped bookmarks** — the pattern sandboxed macOS (and iOS 16+) apps use to re-access files the user picked in a previous session. It sits alongside the `SettingsKey` / `SharedSettings` API rather than going through it, because bookmark data is a single `[String: Data]` map keyed by path and doesn't need the per-key type system.

```swift
import SharedSettings

// After an NSOpenPanel / .onOpenURL / drop, while the URL still has scope:
url.startAccessingSecurityScopedResource()
SecureURLStore.save(url)

// Next launch, given the path you remembered:
if let resolved = SecureURLStore.resolve(url) {
    resolved.startAccessingSecurityScopedResource()
    // …use resolved for file access
}

// Clean up when the file is removed from your recents list:
SecureURLStore.remove(url)
```

`SecureURLStore.save / resolve / remove` are static shortcuts that forward to `SecureURLStore.shared`, which uses `UserDefaults.standard` under the key `com.sharedsettings.secure-urls`. If you want segregated storage (App Groups, tests, multiple bookmark scopes), build your own instance:

```swift
let appGroupStore = SecureURLStore(
    userDefaults: UserDefaults(suiteName: "group.com.example.app")!,
    defaultsKey: "com.example.app.bookmarks"
)
appGroupStore.save(url)
```

A few behaviors worth knowing:

- `save` silently no-ops if the URL doesn't carry a security-scope aura. `bookmarkData(options: .withSecurityScope)` throws in that case, and the error is swallowed — callers that want to know whether scope was valid should check `url.startAccessingSecurityScopedResource()` separately.
- `resolve` refreshes stale bookmarks in place. If the file was moved and the OS still has enough info to locate it, the new bookmark is saved under the new path key.
- The returned URL from `resolve` is ready for `startAccessingSecurityScopedResource()`. That call is **your** responsibility — `SecureURLStore` persists the bookmark but never opens a scope session.

---

## License

MIT
