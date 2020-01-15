//
//  EditorCommandExecutorTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest

import Proton

class EditorCommandExecutorTests: XCTestCase {
    func testExecutesCommandOnEditor() {
        let context = EditorViewContext(name: "test_context")
        let commandExecutor = EditorCommandExecutor(context: context)
        let editor = EditorView(context: context)

        let selectedRange = NSRange(location: 3, length: 3)
        editor.replaceCharacters(in: .zero, with: "This is some text")
        editor.selectedRange = selectedRange

        guard let font = editor.selectedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
            XCTFail("Failed to get font information")
            return
        }

        XCTAssertFalse(font.isBold)

        commandExecutor.execute(BoldCommand())

        guard let updatedFont = editor.selectedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
            XCTFail("Failed to get font information")
            return
        }

        XCTAssertTrue(updatedFont.isBold)
    }
}
