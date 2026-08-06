//
//  DeveloperSettingsScreen.swift
//  SharedSettings
//
//  A ready-made debug menu over one or more settings namespaces.
//

import SwiftUI

/// Lists the settings in the given namespaces, with a live control for each editable one.
///
/// ```swift
/// NavigationLink("Developer") { DeveloperSettingsScreen(DevFlags.self, Build.self) }
/// ```
///
/// The screen self-gates on ``SharedSettings/isDeveloperBuild`` — if an app ships without
/// hiding its entry point, the settings still don't appear.
@MainActor public struct DeveloperSettingsScreen: View {
	private let entries: [SettingsEntry]

	public init(_ namespaces: any SettingsNamespace.Type...) {
		entries = namespaces.flatMap { $0.allSettings }
	}

	public init(entries: [SettingsEntry]) {
		self.entries = entries
	}

	public var body: some View {
		if SharedSettings.isDeveloperBuild {
			SettingsEntryList(entries: entries)
		} else {
			ContentUnavailableView(
				"Developer Settings Unavailable",
				systemImage: "hammer",
				description: Text("This build isn't a developer build.")
			)
		}
	}
}

struct SettingsEntryList: View {
	let entries: [SettingsEntry]

	// Developer flags are what the screen is for, so they lead; baked-in values trail.
	private static let order: [SettingsKind] = [.developer, .user, .buildTime]

	var body: some View {
		List {
			ForEach(Self.order, id: \.self) { kind in
				let matching = entries.filter { $0.kind == kind }
				if !matching.isEmpty {
					Section(kind.title) {
						ForEach(matching) { SettingsEntryRow(entry: $0) }
					}
				}
			}
		}
	}
}
