//
//  SettingEntryMacro.swift
//  SharedSettings
//
//  Backs the per-member @SettingEntry / @BuildSettingEntry attributes that
//  SettingsNamespaceMacro attaches. Generates the SettingsKey type for a member, and — for
//  everything but build settings — rewrites the member into a computed property over it.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct SettingEntryMacro: AccessorMacro, PeerMacro {

	// MARK: - AccessorMacro — the stored property becomes a passthrough to the store.

	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		guard let variable = declaration.as(VariableDeclSyntax.self),
				let setting = SettingDeclaration(variable),
				!setting.isConstant else { return [] }

		// Deliberately routed through SharedSettings, not ObservedSettings: this accessor is
		// nonisolated and callable from anywhere. Views observe via @Setting or SettingsEntry.
		let key = setting.keyTypeName
		return [
			"get { SharedSettings[\(raw: key).self] }",
			"set { SharedSettings[\(raw: key).self] = newValue }",
		]
	}

	// MARK: - PeerMacro — the SettingsKey type itself.

	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let variable = declaration.as(VariableDeclSyntax.self),
				let setting = SettingDeclaration(variable),
				let defaultValue = setting.defaultValue else { return [] }

		let access = setting.access
		// @BuildSettingEntry passes only a storage key, so a missing kind means build-time.
		let kind = argument("kind", in: node) ?? ".buildTime"
		let location = argument("location", in: node) ?? ".userDefaults"
		let storageKey = argument("storageKey", in: node) ?? "\"\(setting.name)\""
		let annotation = setting.typeName.map { ": \($0)" } ?? ""

		let key: DeclSyntax = """
			\(raw: access)struct \(raw: setting.keyTypeName): SettingsKey {
				\(raw: access)static let defaultValue\(raw: annotation) = \(defaultValue)
				\(raw: access)static let name = \(raw: storageKey)
				\(raw: access)static let location: SettingsLocation = \(raw: location)
				\(raw: access)static let kind: SettingsKind = \(raw: kind)
			}
			"""
		return [key]
	}

	private static func argument(_ label: String, in node: AttributeSyntax) -> String? {
		guard case .argumentList(let arguments) = node.arguments else { return nil }
		return arguments.first { $0.label?.text == label }?.expression.trimmedDescription
	}
}
