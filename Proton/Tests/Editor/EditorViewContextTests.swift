//
//  EditorViewContextTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 19/4/20.
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

class EditorViewContextTests: XCTestCase {

    func testGetsActiveEditorViewFromContext() {
        let editor = EditorView()
        let context = EditorViewContext.shared
        context.richTextViewContext.textViewDidBeginEditing(editor.richTextView)
        XCTAssertEqual(context.activeEditorView, editor)
    }

    func testGetsActiveEditorViewAcrossMultipleContexts() {
        let context1 = EditorViewContext(name: "context1")
        let editor1 = EditorView(frame: .zero, context: context1)

        context1.richTextViewContext.textViewDidBeginEditing(editor1.richTextView)

        let context2 = EditorViewContext(name: "context2")
        let editor2 = EditorView(frame: .zero, context: context2)

        context1.richTextViewContext.textViewDidEndEditing(editor1.richTextView)
        context2.richTextViewContext.textViewDidBeginEditing(editor2.richTextView)

        XCTAssertNil(context1.activeEditorView)
        XCTAssertEqual(context2.activeEditorView, editor2)
    }

    func testAppliesSameContextAsParentToNestedEditor() {
        let context = EditorViewContext(name: "context1")
        let editor = EditorView(frame: .zero, context: context)

        let nestedEditor = PanelView(context: context)
        let attachment = Attachment(nestedEditor, size: .fullWidth)
        editor.appendCharacters(attachment.string)

        XCTAssertNotNil(nestedEditor.editor.editorViewContext)
        XCTAssertTrue(nestedEditor.editor.editorViewContext === editor.editorViewContext)
    }

    func testCarriesOverCustomTypingAttributes() {
        let editor = EditorView()
        let context = EditorViewContext.shared
        context.richTextViewContext.textViewDidBeginEditing(editor.richTextView)

        let backgroundStyle = BackgroundStyle(color: .red)
        editor.attributedText = NSAttributedString(string: "abc", attributes: [
            NSAttributedString.Key.backgroundStyle: backgroundStyle
        ])
        _ = context.richTextViewContext.textView(editor.richTextView, shouldChangeTextIn: editor.textEndRange, replacementText: "def")

        XCTAssertTrue(context.activeEditorView?.typingAttributes.contains{ $0.key == .backgroundStyle } ?? false)
        // Validate that existing attributes are not removed
        XCTAssertTrue(context.activeEditorView?.typingAttributes.contains{ $0.key == .paragraphStyle } ?? false)
    }

    func testLockedAttributes() {
        let editor = EditorView()
        let context = EditorViewContext.shared
        context.richTextViewContext.textViewDidBeginEditing(editor.richTextView)

        let backgroundStyle = BackgroundStyle(color: .red)
        editor.attributedText = NSAttributedString(string: "abc", attributes: [
            NSAttributedString.Key.backgroundStyle: backgroundStyle,
            NSAttributedString.Key.foregroundColor: UIColor.red,
            NSAttributedString.Key.lockedAttributes: [NSAttributedString.Key.backgroundStyle],
        ])

        _ = context.richTextViewContext.textView(editor.richTextView, shouldChangeTextIn: editor.textEndRange, replacementText: "test")
        
        XCTAssertTrue(context.activeEditorView?.typingAttributes.contains{ $0.key == .foregroundColor } ?? false)
        XCTAssertFalse(context.activeEditorView?.typingAttributes.contains{ $0.key == .backgroundStyle } ?? true)
    }
}
