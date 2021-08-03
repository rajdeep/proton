//
//  EditorContextDelegateTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 16/4/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
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

class EditorContextDelegateTests: XCTestCase {

    func testDidReceiveKeyInAllEditors() {
        let delegateExpectation = functionExpectation()
        delegateExpectation.expectedFulfillmentCount = 2
        let delegate = MockEditorViewDelegate()

        let editor1 = EditorView()
        let editor2 = EditorView()

        var expectedEditors = [editor1, editor2]
        delegate.onShouldHandleKey = { editor, key, range, _ in
            XCTAssertEqual(editor, expectedEditors[0])
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(range, .zero)
            delegateExpectation.fulfill()
            expectedEditors.remove(at: 0)
        }

        editor1.editorViewContext.delegate = delegate

        let richTextView1 = editor1.richTextView
        let richTextViewDelegate1 = richTextView1.richTextViewDelegate
        var handled = true

        richTextViewDelegate1?.richTextView(richTextView1, shouldHandle: .enter, modifierFlags: [], at: .zero, handled: &handled)

        let richTextView2 = editor2.richTextView
        let richTextViewDelegate2 = richTextView2.richTextViewDelegate

        richTextViewDelegate2?.richTextView(richTextView2, shouldHandle: .enter, modifierFlags: [], at: .zero, handled: &handled)
        waitForExpectations(timeout: 1.0)
    }

    func testDidChangeSelectionInAllEditors() {
        let delegateExpectation = functionExpectation()
        delegateExpectation.expectedFulfillmentCount = 2
        let delegate = MockEditorViewDelegate()

        let editor1 = EditorView()
        let editor2 = EditorView()

        var expectedEditors = [editor1, editor2]
        delegate.onSelectionChanged = { editor, range, _, contentType in
            XCTAssertEqual(editor, expectedEditors[0])
            XCTAssertEqual(range, .zero)
            XCTAssertEqual(contentType, .paragraph)

            delegateExpectation.fulfill()
            expectedEditors.remove(at: 0)
        }

        editor1.editorViewContext.delegate = delegate
        let richTextView1 = editor1.richTextView
        let richTextViewDelegate1 = richTextView1.richTextViewDelegate

        richTextViewDelegate1?.richTextView(richTextView1, didChangeSelection: .zero, attributes: [:], contentType: .paragraph)

        let richTextView2 = editor2.richTextView
        let richTextViewDelegate2 = richTextView2.richTextViewDelegate

        richTextViewDelegate2?.richTextView(richTextView2, didChangeSelection: .zero, attributes: [:], contentType: .paragraph)

        waitForExpectations(timeout: 1.0)
    }

    func testDidReceiveFocusInAllEditors() {
        let delegateExpectation = functionExpectation()
        delegateExpectation.expectedFulfillmentCount = 2

        let delegate = MockEditorViewDelegate()

        let editor1 = EditorView()
        let editor2 = EditorView()

        var expectedEditors = [editor1, editor2]
        let expectedRange = NSRange(location: 4, length: 8)
        delegate.onReceivedFocus = { editor, range in
            XCTAssertEqual(editor, expectedEditors[0])
            XCTAssertEqual(range, expectedRange)
            delegateExpectation.fulfill()
            expectedEditors.remove(at: 0)
        }

        editor1.editorViewContext.delegate = delegate

        let richTextView1 = editor1.richTextView
        let richTextViewDelegate1 = richTextView1.richTextViewDelegate

        richTextViewDelegate1?.richTextView(richTextView1, didReceiveFocusAt: expectedRange)

        let richTextView2 = editor2.richTextView
        let richTextViewDelegate2 = richTextView2.richTextViewDelegate

        richTextViewDelegate2?.richTextView(richTextView1, didReceiveFocusAt: expectedRange)
        waitForExpectations(timeout: 1.0)
    }

    func testDidLoseFocusInAllEditors() {
        let delegateExpectation = functionExpectation()
        delegateExpectation.expectedFulfillmentCount = 2
        let delegate = MockEditorViewDelegate()

        let editor1 = EditorView()
        let editor2 = EditorView()

        var expectedEditors = [editor1, editor2]
        let expectedRange = NSRange(location: 4, length: 8)
        delegate.onLostFocus = { editor, range in
            XCTAssertEqual(editor, expectedEditors[0])
            XCTAssertEqual(range, expectedRange)
            delegateExpectation.fulfill()
            expectedEditors.remove(at: 0)
        }

        editor1.editorViewContext.delegate = delegate

        let richTextView1 = editor1.richTextView
        let richTextViewDelegate1 = richTextView1.richTextViewDelegate

        richTextViewDelegate1?.richTextView(richTextView1, didLoseFocusFrom: expectedRange)

        let richTextView2 = editor2.richTextView
        let richTextViewDelegate2 = richTextView2.richTextViewDelegate

        richTextViewDelegate2?.richTextView(richTextView2, didLoseFocusFrom: expectedRange)
        waitForExpectations(timeout: 1.0)
    }
}
