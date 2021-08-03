//
//  EditorViewMenuTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 30/4/20.
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

class EditorViewMenuTests: XCTestCase {
    func testOverridesCopy() {
        let ex = functionExpectation()
        let editor = TestEditorView()
        editor.onCopy = {
            ex.fulfill()
        }

        editor.richTextView.copy(nil)
        waitForExpectations(timeout: 1.0)
    }

    func testOverridesCut() {
        let ex = functionExpectation()
        let editor = TestEditorView()
        editor.onCut = {
            ex.fulfill()
        }

        editor.richTextView.cut(nil)
        waitForExpectations(timeout: 1.0)
    }

    func testOverridesPaste() {
        let ex = functionExpectation()
        let editor = TestEditorView()
        editor.onPaste = {
            ex.fulfill()
        }

        editor.richTextView.paste(nil)
        waitForExpectations(timeout: 1.0)
    }

    func testOverridesSelect() {
        let ex = functionExpectation()
        let editor = TestEditorView()
        editor.onSelect = {
            ex.fulfill()
        }

        editor.richTextView.select(nil)
        waitForExpectations(timeout: 1.0)
    }

    func testOverridesToggleBold() {
        let ex = functionExpectation()
        let editor = TestEditorView()
        editor.onToggleBold = {
            ex.fulfill()
        }

        editor.richTextView.toggleBoldface(nil)
        waitForExpectations(timeout: 1.0)
    }

    func testOverridesToggleItalics() {
        let ex = functionExpectation()
        let editor = TestEditorView()
        editor.onToggleItalics = {
            ex.fulfill()
        }

        editor.richTextView.toggleItalics(nil)
        waitForExpectations(timeout: 1.0)
    }

    func testOverridesToggleUnderline() {
        let ex = functionExpectation()
        let editor = TestEditorView()
        editor.onToggleUnderline = {
            ex.fulfill()
        }

        editor.richTextView.toggleUnderline(nil)
        waitForExpectations(timeout: 1.0)
    }

    func testDefaultSelectAll() {
        let ex = functionExpectation()
        ex.isInverted = true
        let editor = TestEditorView()
        editor.attributedText = NSAttributedString(attributedString: NSAttributedString(string: "test string"))
        editor.onSelect = {
            ex.fulfill()
        }

        editor.richTextView.selectAll(nil)
        XCTAssertEqual(editor.selectedRange, editor.attributedText.fullRange)
        waitForExpectations(timeout: 1.0)
    }
}

class TestEditorView: EditorView {
    var onCopy: (()->Void)?
    var onPaste: (()->Void)?
    var onCut: (()->Void)?
    var onSelect: (()->Void)?
    var onToggleBold: (()->Void)?
    var onToggleUnderline: (()->Void)?
    var onToggleItalics: (()->Void)?

    #if os(iOS)
    override func copy(_ sender: Any?) {
        onCopy?()
    }

    override func cut(_ sender: Any?) {
        onCut?()
    }

    override func paste(_ sender: Any?) {
        onPaste?()
    }

    override func select(_ sender: Any?) {
        onSelect?()
    }

    override func toggleBoldface(_ sender: Any?) {
        onToggleBold?()
    }

    override func toggleUnderline(_ sender: Any?) {
        onToggleUnderline?()
    }

    override func toggleItalics(_ sender: Any?) {
        onToggleItalics?()
    }
    #else
    // TODO: Implement on macOS
    #endif
}
