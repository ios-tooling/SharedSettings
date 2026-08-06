//
//  SettingsNamespaces.swift
//  SharedSettings
//

@_exported import SharedSettings

/// Declares a namespace of user-facing settings — one line per setting.
///
/// ```swift
/// @UserSettings enum AppSettings {
///     static var showTips: Bool = true
///     static var refreshInterval: Double = 30
/// }
///
/// AppSettings.showTips = false                    // read/write from anywhere
/// @Setting(AppSettings.ShowTips.self) var tips    // observable in a view
/// ```
///
/// Each `static var` becomes a full ``SettingsKey`` (named by capitalizing the property, so
/// `showTips` → `ShowTips`) and registers itself in `allSettings` for settings UI.
/// Members need an explicit type, since the macro turns them into computed properties.
@attached(memberAttribute)
@attached(member, names: named(allSettings))
@attached(extension, conformances: SettingsNamespace)
public macro UserSettings(_ location: SettingsLocation = .userDefaults) =
	#externalMacro(module: "SharedSettingsMacroPlugin", type: "SettingsNamespaceMacro")

/// Declares a namespace of developer-only settings — one line per setting.
///
/// ```swift
/// @DeveloperSettings enum DevFlags {
///     static var useStagingAPI: Bool = false
///     static var animationSpeed: Double = 1
/// }
///
/// NavigationLink("Developer") { DeveloperSettingsScreen(DevFlags.self) }
/// ```
///
/// Identical to ``UserSettings(_:)`` except the keys are marked `.developer`, so they're listed
/// only where ``SharedSettings/isDeveloperBuild`` allows. Reads and writes work in every build.
@attached(memberAttribute)
@attached(member, names: named(allSettings))
@attached(extension, conformances: SettingsNamespace)
public macro DeveloperSettings(_ location: SettingsLocation = .userDefaults) =
	#externalMacro(module: "SharedSettingsMacroPlugin", type: "SettingsNamespaceMacro")

/// Declares a namespace of build-time constants — one line per setting.
///
/// ```swift
/// @BuildSettings enum Build {
///     static let apiBase = "https://api.example.com"
///     static let logsNetworkTraffic = false
/// }
///
/// Build.apiBase   // read-only; no storage is consulted
/// ```
///
/// Members are declared with `let` and stay exactly what you wrote. Each also gets a
/// ``SettingsKey`` (`Build.ApiBase`) whose writes are ignored, so build settings can appear
/// in a debug screen and be read through the same API as everything else.
@attached(memberAttribute)
@attached(member, names: named(allSettings))
@attached(extension, conformances: SettingsNamespace)
public macro BuildSettings() =
	#externalMacro(module: "SharedSettingsMacroPlugin", type: "SettingsNamespaceMacro")

/// Implementation detail of the settings-namespace macros — attached to members automatically.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro SettingEntry(kind: SettingsKind, location: SettingsLocation, storageKey: String) =
	#externalMacro(module: "SharedSettingsMacroPlugin", type: "SettingEntryMacro")

/// Implementation detail of ``BuildSettings()`` — attached to members automatically.
@attached(peer, names: arbitrary)
public macro BuildSettingEntry(storageKey: String) =
	#externalMacro(module: "SharedSettingsMacroPlugin", type: "SettingEntryMacro")
