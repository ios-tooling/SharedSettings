//
//  OptionalWrapper.swift
//  SettingsTest
//
//  Created by Ben Gottlieb on 12/16/25.
//

import Foundation

protocol OptionalBox {
	associatedtype Wrapped
	
	var value: Wrapped? { get }
	static var none: Self { get }
}

extension OptionalBox {
	var none: Wrapped? {
		return nil
	}
}

extension Optional: OptionalBox {
	public var value: Wrapped? {
		switch self {
		case .some(let value): return value
		case .none: return nil
		}
	}
}
