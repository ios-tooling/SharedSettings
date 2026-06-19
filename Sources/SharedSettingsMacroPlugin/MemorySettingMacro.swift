//
//  MemorySettingMacro.swift
//  SharedSettings
//
//  Generates a `SettingsKey` type backed by the in-process `.memory` location.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct MemorySettingMacro: MemberMacro, ExtensionMacro {

	// MARK: - MemberMacro — fill in the SettingsKey requirements.
	// `defaultValue` is emitted untyped so the compiler infers `Payload` from it
	// (e.g. `false` → Bool, `MyEnum.foo` → MyEnum). No type-inference code needed.

	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard case .argumentList(let args) = node.arguments,
				let defaultExpr = args.first?.expression else {
			throw MemorySettingError.missingDefault
		}

		// Propagate the type's access level so a public key gets public witnesses
		// (an internal witness can't satisfy a public SettingsKey conformance).
		let access = accessModifier(of: declaration)

		return [
			"\(raw: access)static let defaultValue = \(defaultExpr)",
			"\(raw: access)static let location: SettingsLocation = .memory",
		]
	}

	// MARK: - ExtensionMacro — add the SettingsKey conformance.

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		if protocols.isEmpty { return [] }   // type already states the conformance
		let decl: DeclSyntax = "extension \(type.trimmed): SettingsKey {}"
		return [decl.cast(ExtensionDeclSyntax.self)]
	}

	// "public " / "package " for cross-module keys, "" otherwise.
	private static func accessModifier(of declaration: some DeclGroupSyntax) -> String {
		for modifier in declaration.modifiers {
			switch modifier.name.tokenKind {
			case .keyword(.public):  return "public "
			case .keyword(.package): return "package "
			default:                 continue
			}
		}
		return ""
	}
}

enum MemorySettingError: Error, CustomStringConvertible {
	case missingDefault

	var description: String {
		switch self {
		case .missingDefault:
			"@MemorySetting requires a default value, e.g. @MemorySetting(false) struct IsReady {}"
		}
	}
}
