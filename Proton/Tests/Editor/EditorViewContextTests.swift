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
        let editor1 = EditorView()
        let context1 = EditorViewContext(name: "context1")
        context1.richTextViewContext.textViewDidBeginEditing(editor1.richTextView)

        let editor2 = EditorView()
        let context2 = EditorViewContext(name: "context2")
        context1.richTextViewContext.textViewDidEndEditing(editor1.richTextView)
        context2.richTextViewContext.textViewDidBeginEditing(editor2.richTextView)

        XCTAssertNil(context1.activeEditorView)
        XCTAssertEqual(context2.activeEditorView, editor2)
    }
}
