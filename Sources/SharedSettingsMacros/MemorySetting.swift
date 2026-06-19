//
//  MemorySetting.swift
//  SharedSettings
//

@_exported import SharedSettings

/// Declares a `.memory`-backed ``SettingsKey`` type from a one-line declaration.
///
/// ```swift
/// @MemorySetting(false) struct IsReady {}
///
/// @Setting(IsReady.self) var isReady   // in a view
/// SharedSettings[IsReady.self] = true  // from anywhere
/// ```
///
/// The payload type is inferred from the default value.
@attached(member, names: named(defaultValue), named(location))
@attached(extension, conformances: SettingsKey)
public macro MemorySetting<Payload>(_ defaultValue: Payload) =
	#externalMacro(module: "SharedSettingsMacroPlugin", type: "MemorySettingMacro")
