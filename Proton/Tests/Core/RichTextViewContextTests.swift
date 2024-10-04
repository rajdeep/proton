//
//  RichTextViewContextTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 7/1/20.
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

@testable import Proton

class RichTextViewContextTests: XCTestCase {

    func testInvokesSelectionChange() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 4, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onSelectionChanged = { _, range, _, _ in
            XCTAssertEqual(range, selectedRange)
            testExpectation.fulfill()
        }

        context.textViewDidChangeSelection(textView)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesReceivedFocus() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 2, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onReceivedFocus = { _, range in
            XCTAssertEqual(range, selectedRange)
            testExpectation.fulfill()
        }

        context.textViewDidBeginEditing(textView)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesLostFocus() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 5, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onLostFocus = { _, range in
            XCTAssertEqual(range, selectedRange)
            testExpectation.fulfill()
        }

        context.textViewDidEndEditing(textView)
        waitForExpectations(timeout: 1.0)
    }

    func testReceiveEnterKey() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 5, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onShouldHandleKey = { _, key, _, range, _ in
            XCTAssertEqual(range, selectedRange)
            XCTAssertEqual(key, EditorKey.enter)
            testExpectation.fulfill()
        }

        _ = context.textView(textView, shouldChangeTextIn: selectedRange, replacementText: "\n")
        waitForExpectations(timeout: 1.0)
    }

    func testReceiveBackspaceKeyInNonEmptyTextView() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 5, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onShouldHandleKey = { _, key, _, range, _ in
            XCTAssertEqual(range, selectedRange)
            XCTAssertEqual(key, EditorKey.backspace)
            testExpectation.fulfill()
        }

        _ = context.textView(textView, shouldChangeTextIn: selectedRange, replacementText: "")
        waitForExpectations(timeout: 1.0)
    }

    func testSelectsAttachmentOnBackspace() {
        let mockTextViewDelegate = MockRichTextViewDelegate()
        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let panelAttachment = Attachment(PanelView(), size: .fullWidth)
        panelAttachment.selectBeforeDelete = true
        textView.insertAttachment(in: textView.textEndRange, attachment: panelAttachment)
        textView.replaceCharacters(in: textView.textEndRange, with: NSAttributedString(string: " "))

        textView.selectedRange = NSRange(location: 12, length: 0)

        XCTAssertFalse(panelAttachment.isSelected)
        _ = context.textView(textView, shouldChangeTextIn: NSRange(location: 11, length: 1), replacementText: "")

        XCTAssertTrue(panelAttachment.isSelected)
        XCTAssertEqual(textView.selectedRange, panelAttachment.rangeInContainer())
    }

    func testInvokesShouldSelectsAttachmentOnBackspace() throws {
        let mockTextViewDelegate = MockRichTextViewDelegate()
        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let panelView = PanelView()
        panelView.editor.attributedText = NSAttributedString(string: "Text in panel")
        let panelAttachment = Attachment(panelView, size: .fullWidth)
        panelAttachment.selectBeforeDelete = false
        textView.insertAttachment(in: textView.textEndRange, attachment: panelAttachment)
        textView.replaceCharacters(in: textView.textEndRange, with: NSAttributedString(string: " "))
        textView.render()
        textView.selectedRange = NSRange(location: 12, length: 0)

        mockTextViewDelegate.onShouldSelectAttachmentOnBackspace = { _, attachment in
            XCTAssertEqual(attachment, panelAttachment)
            return true
        }

        XCTAssertFalse(panelAttachment.isSelected)
        _ = context.textView(textView, shouldChangeTextIn: NSRange(location: 11, length: 1), replacementText: "")
        XCTAssertTrue(panelAttachment.isSelected)
    }

    func testReceiveBackspaceKeyInEmptyTextView() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let selectedRange = NSRange.zero
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onShouldHandleKey = { _, key, _, range, _ in
            XCTAssertEqual(range, selectedRange)
            XCTAssertEqual(key, EditorKey.backspace)
            testExpectation.fulfill()
        }

        _ = context.textView(textView, shouldChangeTextIn: selectedRange, replacementText: "")
        waitForExpectations(timeout: 1.0)
    }

    func testReceiveRightKey() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let selectedRange = NSRange.zero
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onShouldHandleKey = { _, key, _, _, _ in
            guard case let EditorKey.other(actualKey) = key else {
                XCTFail("Expected key not found")
                return
            }
            XCTAssertEqual(actualKey.charactersIgnoringModifiers, UIKeyCommand.inputRightArrow)
            testExpectation.fulfill()
        }

        let uiPresses: Set<UIPress> = [MockUIPress(key: .init(characters: UIKeyCommand.inputRightArrow))]
        textView.pressesBegan(uiPresses, with: nil)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesTextDidChange() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        context.textViewDidBeginEditing(textView)
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 4, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onDidChangeText = { _, range in
            XCTAssertEqual(range, selectedRange)
            testExpectation.fulfill()
        }

        context.textViewDidChange(textView)
        
        waitForExpectations(timeout: 1.0)
    }

    func testRelaysAttributesAtSelectedRange() {
        let testExpectation = expectation(description: #function)
        testExpectation.expectedFulfillmentCount = 2

        let mockTextViewDelegate = MockRichTextViewDelegate()

        let key1 = NSAttributedString.Key("key1")
        let key2 = NSAttributedString.Key("key2")

        let context = RichTextViewContext()
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let key1Range = NSRange(location: 2, length: 1)
        let key2Range = NSRange(location: 4, length: 1)

        textView.addAttributes([key1: 1], range: key1Range)
        textView.addAttributes([key2: 2], range: key2Range)

        var run = 0
        mockTextViewDelegate.onSelectionChanged = { _, _, attributes, _ in
            if run == 0 {
                XCTAssertEqual(attributes[key1] as? Int, 1)
            } else {
                XCTAssertEqual(attributes[key2] as? Int, 2)
            }
            run += 1
            testExpectation.fulfill()
        }

        // run 1
        textView.selectedRange = key1Range

        // run 2
        textView.selectedRange = key2Range

        waitForExpectations(timeout: 1.0)
    }

    func testSetsSelectedEditorOnTextRangeChange() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate

        textView.isEditable = false
        textView.text = "Sample text"
        textView.selectedRange = .zero

        mockTextViewDelegate.onSelectionChanged = { _, _, _, _ in
            XCTAssertEqual(context.selectedTextView, textView)
            testExpectation.fulfill()
        }

        context.textViewDidChangeSelection(textView)

        waitForExpectations(timeout: 1.0)
    }

    func testUnsetsSelectedEditorOnTextRangeNil() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate

        textView.text = "Sample text"
        textView.selectedTextRange = nil

        mockTextViewDelegate.onSelectionChanged = { _, _, _, _ in
            XCTAssertNil(context.selectedTextView)
            testExpectation.fulfill()
        }

        context.textViewDidChangeSelection(textView)

        waitForExpectations(timeout: 1.0)
    }

    func testSetsSelectedEditorOnTap() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate

        textView.text = "Sample text"
        textView.selectedTextRange = nil

        mockTextViewDelegate.onDidTapAtLocation = { _, _, _ in
            XCTAssertEqual(context.selectedTextView, textView)
            testExpectation.fulfill()
        }

        textView.didTap(at: .zero)

        waitForExpectations(timeout: 1.0)
    }

    func testInvokesScrollCHanged() {
        let testExpectation = expectation(description: #function)
        testExpectation.expectedFulfillmentCount = 2
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let textView = RichTextView(frame: frame, context: context, allowAutogrowing: true)
        textView.richTextViewDelegate = mockTextViewDelegate

        textView.text = "Sample text"

        var expectedValue = [true, false]
        mockTextViewDelegate.onDidChangeScrollEnabled = { _, isScrollEnabled in
            XCTAssertEqual(isScrollEnabled, expectedValue.first)
            expectedValue.remove(at: 0)
            testExpectation.fulfill()
        }

        textView.text = "\n\n\n\n\n\n\n\n"
        textView.render(size: textView.frame.size)

        textView.text = ""
        textView.render(size: textView.frame.size)

        waitForExpectations(timeout: 1.0)
    }

}
