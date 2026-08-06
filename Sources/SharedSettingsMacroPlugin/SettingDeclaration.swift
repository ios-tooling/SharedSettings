//
//  SettingDeclaration.swift
//  SharedSettings
//
//  Shared parsing for the members of a settings namespace.
//

import SwiftSyntax
import SwiftDiagnostics

/// One `static var`/`static let` member of a settings-namespace enum.
struct SettingDeclaration {
	let name: String              // "useStagingAPI"
	let typeName: String?         // "Bool", when annotated
	let defaultValue: ExprSyntax?
	let isConstant: Bool          // declared with `let`
	let access: String            // "public " / "package " / ""

	/// The generated `SettingsKey` type: `useStagingAPI` → `UseStagingAPI`.
	var keyTypeName: String {
		let capitalized = name.prefix(1).uppercased() + name.dropFirst()
		return capitalized == name ? name + "Key" : capitalized
	}

	/// "useStagingAPI" → "Use Staging API"
	var title: String { SettingDeclaration.humanized(name) }

	/// Returns nil for anything that isn't a single-binding static property — nested types,
	/// methods, and instance properties are left alone.
	init?(_ variable: VariableDeclSyntax) {
		guard variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
				variable.bindings.count == 1,
				let binding = variable.bindings.first,
				let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
				binding.accessorBlock == nil else { return nil }

		name = pattern.identifier.text
		typeName = binding.typeAnnotation?.type.trimmedDescription
		defaultValue = binding.initializer?.value
		isConstant = variable.bindingSpecifier.tokenKind == .keyword(.let)
		access = SettingDeclaration.accessModifier(of: variable.modifiers)
	}

	static func accessModifier(of modifiers: DeclModifierListSyntax) -> String {
		for modifier in modifiers {
			switch modifier.name.tokenKind {
			case .keyword(.public):  return "public "
			case .keyword(.package): return "package "
			default:                 continue
			}
		}
		return ""
	}

	// Split on camel-case boundaries, keeping acronym runs together (`useStagingAPI`,
	// not `use Staging A P I`).
	static func humanized(_ name: String) -> String {
		let characters = Array(name)
		var result = ""

		for (index, character) in characters.enumerated() {
			if index > 0, character.isUppercase {
				let previous = characters[index - 1]
				let startsWord = index + 1 < characters.count && characters[index + 1].isLowercase
				if !previous.isUppercase || startsWord { result.append(" ") }
			}
			result.append(character)
		}
		return result.prefix(1).uppercased() + result.dropFirst()
	}
}

struct SettingsMacroDiagnostic: DiagnosticMessage {
	let message: String
	let severity = DiagnosticSeverity.error
	var diagnosticID: MessageID { MessageID(domain: "SharedSettings", id: message) }

	static func needsVar(_ name: String) -> Self {
		.init(message: "'\(name)' must be declared with 'var' — the macro turns it into a computed property")
	}

	static func needsLet(_ name: String) -> Self {
		.init(message: "'\(name)' must be declared with 'let' — build settings are fixed at compile time")
	}

	static func needsType(_ name: String) -> Self {
		.init(message: "'\(name)' needs an explicit type, e.g. 'static var \(name): Bool = false'")
	}

	static func needsDefault(_ name: String) -> Self {
		.init(message: "'\(name)' needs a default value, e.g. 'static var \(name): Bool = false'")
	}
}
