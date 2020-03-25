//
//  RichTextViewContextTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 7/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest

@testable import Proton

class RichTextViewContextTests: XCTestCase {

    func testInvokesSelectionChange() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: RichTextViewContext())
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
        let textView = RichTextView(context: RichTextViewContext())
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
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 5, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onKeyReceived = { _, key, _, range, _ in
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
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 5, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onKeyReceived = { _, key, _, range, _ in
            XCTAssertEqual(range, selectedRange)
            XCTAssertEqual(key, EditorKey.backspace)
            testExpectation.fulfill()
        }

        _ = context.textView(textView, shouldChangeTextIn: selectedRange, replacementText: "")
        waitForExpectations(timeout: 1.0)
    }

    func testReceiveBackspaceKeyInEmptyTextView() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let selectedRange = NSRange.zero
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onKeyReceived = { _, key, _, range, _ in
            XCTAssertEqual(range, selectedRange)
            XCTAssertEqual(key, EditorKey.backspace)
            testExpectation.fulfill()
        }

        _ = context.textView(textView, shouldChangeTextIn: selectedRange, replacementText: "")
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesTextDidChange() {
        let testExpectation = expectation(description: #function)
        let mockTextViewDelegate = MockRichTextViewDelegate()

        let context = RichTextEditorContext.default
        let textView = RichTextView(context: context)
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 4, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onDidChangeText = { _, range in
            XCTAssertEqual(range, selectedRange)
            testExpectation.fulfill()
        }

        _ = context.textViewDidChange(textView)
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
}
