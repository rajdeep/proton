//
//  XCTestHelpers.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest

/// Unwraps an optional value, failing the current test if it is `nil`.
///
/// - Parameters:
///   - value: Optional value
///   - message: Message to use in the test failure if the provided value is `nil`.
/// - Returns: The unwrapped value
public func assertUnwrap<T>(_ value: T?, _ message: String = "Unexpected nil value", file: StaticString = #file, line: UInt = #line) -> T {
    guard let value = value else {
        XCTFail(message, file: file, line: line)
        preconditionFailure(message, file: file, line: line)
    }
    return value
}

extension XCTestCase {
    open func functionExpectation(_ id: String = "", caller: String = #function) -> XCTestExpectation {
        return expectation(description: "\(caller)\(id)")
    }
}
