//
//  RichTextViewTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 4/1/20.
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
import UIKit

@testable import Proton

class RichTextViewTests: XCTestCase {
    func testGetsAttributeAtLocation() {
        let key = NSAttributedString.Key("test_key")
        let value = "value"
        let viewController = SnapshotTestViewController()
        let textView = RichTextView(frame: .zero, context: RichTextViewContext(), growsInfinitely: true)
        textView.translatesAutoresizingMaskIntoConstraints = false
        let attributedText = NSMutableAttributedString(string: "This is a test string")
        attributedText.addAttributes([key: value], range: NSRange(location: 0, length: 4))

        textView.attributedText = attributedText

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])

        viewController.render()

        // character at index 1
        let point1 = CGPoint(x: 20, y: 10)
        let attribute1 = textView.attributeValue(at: point1, for: key) as? String

        // character at index 8
        let point2 = CGPoint(x: 60, y: 10)
        let attribute2 = textView.attributeValue(at: point2, for: key) as? String

        XCTAssertEqual(attribute1, value)
        XCTAssertNil(attribute2)
    }

    func testResetsTypingAttributesOnDeleteBackwards() throws {
        let text = NSAttributedString(string: "a", attributes: [.foregroundColor: UIColor.blue])
        let textView = RichTextView(context: RichTextViewContext(), growsInfinitely: true)
        textView.attributedText = text
        let preColor = try XCTUnwrap(textView.typingAttributes[.foregroundColor] as? UIColor)
        XCTAssertEqual(preColor, UIColor.blue)
        textView.deleteBackward()
        let postColor = try XCTUnwrap(textView.typingAttributes[.foregroundColor] as? UIColor)
        let typingAttributeColor = try XCTUnwrap(textView.defaultTypingAttributes[.foregroundColor] as? UIColor)
        XCTAssertEqual(postColor, typingAttributeColor)
    }

    func testNotifiesDelegateOfSelectedRangeChanges() {
        let funcExpectation = functionExpectation()
        let textView = RichTextView(context: RichTextViewContext(), growsInfinitely: true)
        let richTextViewDelegate = MockRichTextViewDelegate()
        textView.richTextViewDelegate = richTextViewDelegate
        textView.attributedText = NSAttributedString(string: "This is a test string")
        let rangeToSet = NSRange(location: 5, length: 3)

        richTextViewDelegate.onSelectedRangeChanged = { _, old, new in
            XCTAssertEqual(old, textView.textEndRange)
            XCTAssertEqual(new, rangeToSet)
            funcExpectation.fulfill()
        }
        textView.selectedTextRange = rangeToSet.toTextRange(textInput: textView)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesDelegateOnShiftTab() {
        let assertions: ((EditorKey, UIKeyModifierFlags) -> Void) = { key, flags in
            XCTAssertEqual(key, .tab)
            XCTAssertEqual(flags, .shift)
        }
        assertKeyCommand(input: "\t", modifierFlags: .shift, assertions: assertions)
    }

    func testInvokesDelegateOnShiftEnter() {
        let assertions: ((EditorKey, UIKeyModifierFlags) -> Void) = { key, flags in
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(flags, .shift)
        }
        assertKeyCommand(input: "\r", modifierFlags: .shift, assertions: assertions)
    }

    func testInvokesDelegateOnAltEnter() {
        let assertions: ((EditorKey, UIKeyModifierFlags) -> Void) = { key, flags in
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(flags, .alternate)
        }
        assertKeyCommand(input: "\r", modifierFlags: .alternate, assertions: assertions)
    }

    func testInvokesDelegateOnControlEnter() {
        let assertions: ((EditorKey, UIKeyModifierFlags) -> Void) = { key, flags in
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(flags, .control)
        }
        assertKeyCommand(input: "\r", modifierFlags: .control, assertions: assertions)
    }

    func testDeleteBackwards() {
        let text = NSAttributedString(string: "test")
        let textView = RichTextView(context: RichTextViewContext(), growsInfinitely: true)
        textView.attributedText = text
        textView.selectedRange = textView.textEndRange
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "tes")
    }

    func testDeleteBackwardsToEmpty() {
        let text = NSAttributedString(string: "A")
        let textView = RichTextView(context: RichTextViewContext(), growsInfinitely: true)
        textView.attributedText = text
        textView.selectedRange = textView.textEndRange
        textView.deleteBackward()
        // delete on empty
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "")
    }

    func testDeleteBackwardsWithSelection() {
        let text = NSAttributedString(string: "test")
        let textView = RichTextView(context: RichTextViewContext(), growsInfinitely: true)
        textView.attributedText = text
        textView.selectedRange = text.fullRange
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "")
    }

    private func assertKeyCommand(input: String, modifierFlags: UIKeyModifierFlags, assertions: @escaping ((EditorKey, UIKeyModifierFlags) -> Void), file: StaticString = #file, line: UInt = #line) {
        let funcExpectation = functionExpectation()
        let textView = RichTextView(context: RichTextViewContext(), growsInfinitely: true)
        let richTextViewDelegate = MockRichTextViewDelegate()
        textView.richTextViewDelegate = richTextViewDelegate

        richTextViewDelegate.onDidReceiveKey = { _, key, flags, _  in
            assertions(key, flags)
            funcExpectation.fulfill()
        }

        let command = UIKeyCommand(input: input, modifierFlags: modifierFlags, action: #selector(dummySelector))
        textView.handleKeyCommand(command: command)

        waitForExpectations(timeout: 1.0)
    }

    @objc
    private func dummySelector() { }
}
