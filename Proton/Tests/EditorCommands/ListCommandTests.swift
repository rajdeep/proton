//
//  ListCommandTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 7/6/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import XCTest

import Proton

class ListCommandTests: XCTestCase {
    func testAddsAttribute() {
        let editor = EditorView()
        let value = "list"
        editor.appendCharacters("Test 1\nTest 2")
        let command = ListCommand()
        editor.selectedRange = editor.attributedText.fullRange
        command.execute(on: editor, attributeValue: value)

        let lines = editor.contentLinesInRange(editor.attributedText.fullRange)
        XCTAssertEqual(lines[0].text.attribute(.listItem, at: 0, effectiveRange: nil) as? String, value)
        XCTAssertEqual(lines[1].text.attribute(.listItem, at: 0, effectiveRange: nil) as? String, value)
    }

    func testRemovesAttribute() {
        let editor = EditorView()
        let value = "list"
        editor.appendCharacters("Test 1\nTest 2")
        let command = ListCommand()
        editor.selectedRange = editor.attributedText.fullRange
        command.execute(on: editor, attributeValue: value)

        command.execute(on: editor, attributeValue: nil)

        let lines = editor.contentLinesInRange(editor.attributedText.fullRange)
        XCTAssertNil(lines[0].text.attribute(.listItem, at: 0, effectiveRange: nil))
        XCTAssertNil(lines[1].text.attribute(.listItem, at: 0, effectiveRange: nil))
    }

    func testListIndentingWithNoContent() {
        let editor = EditorView()
        let command = ListIndentCommand(indentMode: .outdent)

        XCTAssertFalse(command.canExecute(on: editor))
    }
}
