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

        let context = RichTextViewContext.default
        let textView = RichTextView()
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

        let context = RichTextViewContext.default
        let textView = RichTextView()
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

        let context = RichTextViewContext.default
        let textView = RichTextView()
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

        let context = RichTextViewContext.default
        let textView = RichTextView()
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 5, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onKeyReceived = { _, key, range, _ in
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

        let context = RichTextViewContext.default
        let textView = RichTextView()
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let selectedRange = NSRange(location: 5, length: 1)
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onKeyReceived = { _, key, range, _ in
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

        let context = RichTextViewContext.default
        let textView = RichTextView()
        textView.richTextViewDelegate = mockTextViewDelegate
        textView.text = "Sample text"

        let selectedRange = NSRange.zero
        textView.selectedRange = selectedRange

        mockTextViewDelegate.onKeyReceived = { _, key, range, _ in
            XCTAssertEqual(range, selectedRange)
            XCTAssertEqual(key, EditorKey.backspace)
            testExpectation.fulfill()
        }

        _ = context.textView(textView, shouldChangeTextIn: selectedRange, replacementText: "")
        waitForExpectations(timeout: 1.0)
    }

}
