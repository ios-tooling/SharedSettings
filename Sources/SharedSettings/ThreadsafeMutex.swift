//
//  ThreadsafeMutex.swift
//  SharedSettings
//
//  Created by Ben Gottlieb on 1/11/26.
//


import Foundation
import os.lock

@available(iOS 16.0, watchOS 9, macOS 14, *)
final class ThreadsafeMutex<T: Sendable>: @unchecked Sendable {
	private let lock: OSAllocatedUnfairLock<T>
	
	init(_ v: T) {
		lock = .init(initialState: v)
	}
	
	nonisolated var value: T {
		get {
			lock.withLock { value in value }
		}
		
		set {
			lock.withLock { value in value = newValue }
		}
	}
	
	nonisolated func set(_ value: T) {
		self.value = value
	}
	
	nonisolated func perform(block: @Sendable (inout T) -> Void) {
		lock.withLock { value in
			block(&value)
		}
	}
}
