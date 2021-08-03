//
//  FontTraitToggleCommandTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 8/1/20.
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

class FontTraitToggleCommandTests: XCTestCase {
    func testSetsTypingAttributesInEmptyEditor() throws {
        let editor = EditorView()
        let command = BoldCommand()

        let font: PlatformFont = try XCTUnwrap(editor.typingAttributes[.font] as? PlatformFont)
        XCTAssertFalse(font.isBold)
        command.execute(on: editor)

        let updatedFont = try XCTUnwrap(editor.typingAttributes[.font] as? PlatformFont)
        XCTAssertTrue(updatedFont.isBold)
    }

    func testSetsToggledTypingAttributesInEmptySelectionInNonEmptyEditor() throws {
        let editor = EditorView()
        editor.replaceCharacters(in: .zero, with: "This is a test")
        editor.selectedRange = NSRange(location: 0, length: 4)
        let command = ItalicsCommand()
        command.execute(on: editor)

        editor.selectedRange = NSRange(location: 4, length: 0)
        command.execute(on: editor)

        let updatedFont = try XCTUnwrap(editor.typingAttributes[.font] as? PlatformFont)
        XCTAssertFalse(updatedFont.isItalics)
    }

    func testTogglesFontInRangeBasedOnInitialFontStyle() {
        let commandExpectation = functionExpectation()
        commandExpectation.expectedFulfillmentCount = 3

        let editor = EditorView()
        editor.replaceCharacters(in: .zero, with: "This is some text")

        editor.selectedRange = NSRange(location: 0, length: 7)
        BoldCommand().execute(on: editor)

        editor.selectedRange = NSRange(location: 5, length: 3)
        ItalicsCommand().execute(on: editor)

        editor.selectedRange = NSRange(location: 5, length: 7)
        BoldCommand().execute(on: editor)

        let editorText = editor.attributedText

        let expectedValues: [(text: String, isBold: Bool, isItalics: Bool)] = [
            (text: "This ", isBold: true, isItalics: false),
            (text: "is ", isBold: false, isItalics: true),
            (text: "some text", isBold: false, isItalics: false),
        ]
        var counter = 0
        editorText.enumerateAttribute(.font, in: editorText.fullRange, options: .longestEffectiveRangeNotRequired) { (font, range, _) in
            let text = editorText.attributedSubstring(from: range)
            guard let font = try? XCTUnwrap(text.attribute(.font, at: 0, effectiveRange: nil) as? PlatformFont) else {
                XCTFail("Unable to get font information")
                return
            }

            let expectedValue = expectedValues[counter]

            XCTAssertEqual(text.string, expectedValue.text)
            XCTAssertEqual(font.isBold, expectedValue.isBold)
            XCTAssertEqual(font.isItalics, expectedValue.isItalics)

            counter += 1
            commandExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

}
