//
//  Keychain+Memory.swift
//  SharedSettings
//
//  Keychain settings kept in memory, for hosts that cannot reach the keychain.
//
//  A test host without a keychain entitlement (Swift package tests on the iOS
//  Simulator) has every write refused with errSecMissingEntitlement (-34018)
//  and every read come back empty, so a keychain-backed setting can never be
//  read back. Switched on, the same items live in a dictionary instead, under
//  the same service and account, starting empty.
//

import Foundation
import os

extension Keychain {
	/// Items by service and account while in memory; nil uses the system keychain.
	nonisolated static let memory = OSAllocatedUnfairLock<[String: Data]?>(initialState: nil)

	nonisolated static var usesMemory: Bool { memory.withLock { $0 != nil } }

	nonisolated static func memoryKey(_ key: String, service: String) -> String { service + "\u{0}" + key }
}

public extension SharedSettings {
	/// Keep `.keychain` settings in memory from here on, starting empty. For
	/// test hosts that cannot use the keychain; never for an app.
	static func useInMemoryKeychain() { Keychain.memory.withLock { $0 = [:] } }

	/// Go back to the system keychain, dropping what was held in memory.
	static func useSystemKeychain() { Keychain.memory.withLock { $0 = nil } }
}
