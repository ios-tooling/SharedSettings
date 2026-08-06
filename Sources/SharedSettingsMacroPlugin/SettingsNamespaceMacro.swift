//
//  SettingsNamespaceMacro.swift
//  SharedSettings
//
//  Backs @UserSettings, @DeveloperSettings, and @BuildSettings. Each member of the namespace
//  is tagged with an entry macro (which generates its SettingsKey), and the namespace itself
//  gets the `allSettings` catalog that settings UI reads.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct SettingsNamespaceMacro: MemberAttributeMacro, MemberMacro, ExtensionMacro {

	// MARK: - MemberAttributeMacro — tag each setting with the entry macro.

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingAttributesFor member: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AttributeSyntax] {
		guard let variable = member.as(VariableDeclSyntax.self),
				let setting = SettingDeclaration(variable) else { return [] }

		let kind = kind(of: node)
		guard validate(setting, kind: kind, on: variable, in: context) else { return [] }

		let storageKey = "\"\(namespaceName(of: declaration)).\(setting.name)\""
		if kind == buildTimeKind {
			return ["@BuildSettingEntry(storageKey: \(raw: storageKey))"]
		}
		return ["@SettingEntry(kind: .\(raw: kind), location: \(raw: location(of: node)), storageKey: \(raw: storageKey))"]
	}

	// MARK: - MemberMacro — the catalog a settings screen enumerates.

	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let settings = self.settings(in: declaration, kind: kind(of: node))
		let access = SettingDeclaration.accessModifier(of: declaration.modifiers)

		if settings.isEmpty {
			return ["\(raw: access)static let allSettings: [SettingsEntry] = []"]
		}

		let entries = settings
			.map { "\t\($0.keyTypeName).entry(title: \"\($0.title)\")," }
			.joined(separator: "\n")
		return ["\(raw: access)static let allSettings: [SettingsEntry] = [\n\(raw: entries)\n]"]
	}

	// MARK: - ExtensionMacro — the SettingsNamespace conformance.

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		if protocols.isEmpty { return [] }   // type already states the conformance
		let decl: DeclSyntax = "extension \(type.trimmed): SettingsNamespace {}"
		return [decl.cast(ExtensionDeclSyntax.self)]
	}

	// MARK: - Shared

	static let buildTimeKind = "buildTime"

	/// Which of the three macros is being expanded.
	static func kind(of node: AttributeSyntax) -> String {
		switch node.attributeName.trimmedDescription {
		case "DeveloperSettings": "developer"
		case "BuildSettings": buildTimeKind
		default: "user"
		}
	}

	/// The optional storage location argument, e.g. `@DeveloperSettings(.memory)`.
	static func location(of node: AttributeSyntax) -> String {
		guard case .argumentList(let arguments) = node.arguments,
				let first = arguments.first else { return ".userDefaults" }
		return first.expression.trimmedDescription
	}

	static func namespaceName(of declaration: some DeclGroupSyntax) -> String {
		if let namespace = declaration.as(EnumDeclSyntax.self) { return namespace.name.text }
		if let namespace = declaration.as(StructDeclSyntax.self) { return namespace.name.text }
		if let namespace = declaration.as(ClassDeclSyntax.self) { return namespace.name.text }
		return "Settings"
	}

	/// The valid settings in declaration order. Invalid ones are skipped here and diagnosed by
	/// the member-attribute pass, which has the precise member to point at.
	static func settings(in declaration: some DeclGroupSyntax, kind: String) -> [SettingDeclaration] {
		declaration.memberBlock.members.compactMap { member in
			guard let variable = member.decl.as(VariableDeclSyntax.self),
					let setting = SettingDeclaration(variable),
					setting.defaultValue != nil,
					setting.isConstant == (kind == buildTimeKind),
					kind == buildTimeKind || setting.typeName != nil else { return nil }
			return setting
		}
	}

	static func validate(
		_ setting: SettingDeclaration,
		kind: String,
		on variable: VariableDeclSyntax,
		in context: some MacroExpansionContext
	) -> Bool {
		func fail(_ message: SettingsMacroDiagnostic) -> Bool {
			context.diagnose(Diagnostic(node: Syntax(variable), message: message))
			return false
		}

		if setting.defaultValue == nil { return fail(.needsDefault(setting.name)) }

		if kind == buildTimeKind {
			if !setting.isConstant { return fail(.needsLet(setting.name)) }
		} else {
			if setting.isConstant { return fail(.needsVar(setting.name)) }
			if setting.typeName == nil { return fail(.needsType(setting.name)) }
		}
		return true
	}
}
