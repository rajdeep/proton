//
//  EditorViewDelegateTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import XCTest

@testable import Proton

class EditorViewDelegateTests: XCTestCase {
    func testDidReceiveKey() {
        let delegateExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()
        delegate.onKeyReceived = { _, key, range, _ in
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(range, .zero)
            delegateExpectation.fulfill()
        }

        let editor = EditorView()
        editor.delegate = delegate
        let richTextView = editor.richTextView
        let richTextViewDelegate = richTextView.richTextViewDelegate
        var handled = true

        richTextViewDelegate?.richTextView(richTextView, didReceiveKey: .enter, at: .zero, handled: &handled)
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
}
