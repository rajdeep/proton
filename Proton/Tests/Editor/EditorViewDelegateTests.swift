//
//  EditorViewDelegateTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 9/1/20.
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
import UIKit
import XCTest

@testable import Proton

class EditorViewDelegateTests: XCTestCase {

    func testDidReceiveKey() {
        let delegateExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()
        delegate.onKeyReceived = { editor, key, range  in
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(range, .zero)
            delegateExpectation.fulfill()
        }

        let editor = EditorView()
        editor.delegate = delegate
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate

        richTextViewDelegate?.richTextView(richTextView, didReceive: .enter, modifierFlags: [], at: .zero)
        waitForExpectations(timeout: 1.0)
    }

    func testShouldHandleKey() {
        let delegateExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()
        delegate.onShouldHandleKey = { editor, key, range, _  in
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(range, .zero)
            delegateExpectation.fulfill()
        }

        let editor = EditorView()
        editor.delegate = delegate
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate
        var handled = true

        richTextViewDelegate?.richTextView(richTextView, shouldHandle: .enter, modifierFlags: [], at: .zero, handled: &handled)
        waitForExpectations(timeout: 1.0)
    }

    func testDidChangeSelection() {
        let delegateExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()

        delegate.onSelectionChanged = { _, range, _, contentType in
            XCTAssertEqual(range, .zero)
            XCTAssertEqual(contentType, .paragraph)

            delegateExpectation.fulfill()
        }

        let editor = EditorView()
        editor.delegate = delegate
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate

        richTextViewDelegate?.richTextView(richTextView, didChangeSelection: .zero, attributes: [:], contentType: .paragraph)
        waitForExpectations(timeout: 1.0)
    }

    func testDidReceiveFocus() {
        let delegateExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()

        let expectedRange = NSRange(location: 4, length: 8)
        delegate.onReceivedFocus = { _, range in
            XCTAssertEqual(range, expectedRange)
            delegateExpectation.fulfill()
        }

        let editor = EditorView()
        editor.delegate = delegate
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate

        richTextViewDelegate?.richTextView(richTextView, didReceiveFocusAt: expectedRange)
        waitForExpectations(timeout: 1.0)
    }

    func testDidLoseFocus() {
        let delegateExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()

        let expectedRange = NSRange(location: 4, length: 8)
        delegate.onLostFocus = { _, range in
            XCTAssertEqual(range, expectedRange)
            delegateExpectation.fulfill()
        }

        let editor = EditorView()
        editor.delegate = delegate
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate

        richTextViewDelegate?.richTextView(richTextView, didLoseFocusFrom: expectedRange)
        waitForExpectations(timeout: 1.0)
    }

    func testNotifiesBackspace() throws {
        try assertKeyPress(.backspace, replacementText: "")
    }

    func testNotifiesEnter() throws {
        try assertKeyPress(.enter, replacementText: "\n")
    }

    func testNotifiesTab() throws {
        try assertKeyPress(.tab, replacementText: "\t")
    }

    func testNotifiesTextProcessorsOnDidReceiveFocus() {
        let expectation = functionExpectation()
        let mockProcessor = MockTextProcessor()
        mockProcessor.onDidReceiveFocus = { _ in
            expectation.fulfill()
        }
        let editor = EditorView()
        editor.textProcessor?.register(mockProcessor)
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate

        richTextViewDelegate?.richTextView(richTextView, didReceiveFocusAt: .zero)

        waitForExpectations(timeout: 1.0)
    }

    func testNotifiesTextProcessorsOnDidLoseFocus() {
        let expectation = functionExpectation()
        let mockProcessor = MockTextProcessor()
        mockProcessor.onDidLoseFocus = { _ in
            expectation.fulfill()
        }
        let editor = EditorView()
        editor.textProcessor?.register(mockProcessor)
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate

        richTextViewDelegate?.richTextView(richTextView, didLoseFocusFrom: .zero)

        waitForExpectations(timeout: 1.0)
    }

    private func assertKeyPress(_ key: EditorKey, replacementText: String, file: StaticString = #file, line: UInt = #line) throws {
        let delegateExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()
        delegate.onShouldHandleKey = { editor, key, range, _ in
            XCTAssertEqual(key, key, file: file, line: line)
            XCTAssertEqual(range, .zero, file: file, line: line)
            delegateExpectation.fulfill()
        }

        let editor = EditorView()
        editor.delegate = delegate

        let context = try XCTUnwrap(editor.richTextView.delegate)
        context.textViewDidBeginEditing?(editor.richTextView)
        _ = context.textView?(editor.richTextView, shouldChangeTextIn: editor.selectedRange, replacementText: replacementText)

        waitForExpectations(timeout: 1.0)
    }

}
