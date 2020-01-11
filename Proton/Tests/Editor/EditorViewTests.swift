//
//  EditorViewTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import XCTest

@testable import Proton

class EditorViewTests: XCTestCase {
    func testInvokesRegisteredProcessor() {
        let testExpectation = functionExpectation()
        let editor = EditorView()
        let testString = "test"

        let mockProcessor = MockTextProcessor { editor, editedRange in
            let text = editor.attributedText.attributedSubstring(from: editedRange).string
            XCTAssertEqual(text, testString)
            testExpectation.fulfill()
            return true
        }

        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: .zero, with: testString)
        waitForExpectations(timeout: 1.0)
    }
}
