//
//  Plugin.swift
//  SharedSettings
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SharedSettingsMacroPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [MemorySettingMacro.self]
}
