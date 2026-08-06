//
//  SettingsEntryRow.swift
//  SharedSettings
//
//  Picks a control for a type-erased setting.
//

import SwiftUI

struct SettingsEntryRow: View {
	let entry: SettingsEntry

	var body: some View {
		if !entry.isEditable {
			ReadOnlySettingRow(entry: entry)
		} else if entry.value(as: Bool.self) != nil {
			Toggle(entry.title, isOn: entry.binding(Bool.self, fallback: false))
		} else if entry.value(as: String.self) != nil {
			LabeledSettingField(title: entry.title) {
				TextField(entry.title, text: entry.binding(String.self, fallback: ""))
			}
		} else if entry.value(as: Int.self) != nil {
			LabeledSettingField(title: entry.title) {
				TextField(entry.title, value: entry.binding(Int.self, fallback: 0), format: .number)
			}
		} else if entry.value(as: Double.self) != nil {
			LabeledSettingField(title: entry.title) {
				TextField(entry.title, value: entry.binding(Double.self, fallback: 0), format: .number)
			}
		} else {
			// Anything else (enums, arrays, custom Codable payloads) is shown but not edited.
			ReadOnlySettingRow(entry: entry)
		}
	}
}

// A bare TextField in a List hides its own label, so the title comes from LabeledContent.
struct LabeledSettingField<Field: View>: View {
	let title: String
	@ViewBuilder let field: Field

	var body: some View {
		LabeledContent(title) {
			field
				.labelsHidden()
				.multilineTextAlignment(.trailing)
		}
	}
}

struct ReadOnlySettingRow: View {
	let entry: SettingsEntry

	var body: some View {
		LabeledContent(entry.title) {
			Text(entry.displayValue)
				.foregroundStyle(.secondary)
		}
	}
}
