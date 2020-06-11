//
//  MockEditorViewDelegate.swift
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

@testable import Proton

class MockEditorViewDelegate: EditorViewDelegate {
    var onSelectionChanged: ((EditorView, NSRange, [NSAttributedString.Key: Any], EditorContent.Name) -> Void)?
    var onKeyReceived: ((EditorView, EditorKey, NSRange) -> Void)?
    var onShouldHandleKey: ((EditorView, EditorKey, NSRange, Bool) -> Void)?
    var onReceivedFocus: ((EditorView, NSRange) -> Void)?
    var onLostFocus: ((EditorView, NSRange) -> Void)?
    var onDidExecuteProcessors: ((EditorView, [TextProcessing], NSRange) -> Void)?

    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        onSelectionChanged?(editor, range, attributes, contentType)
    }

    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange) {
        onKeyReceived?(editor, key, range)
    }

    func editor(_ editor: EditorView, shouldHandle key: EditorKey, at range: NSRange, handled: inout Bool) {
        onShouldHandleKey?(editor, key, range, handled)
    }

    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) {
        onReceivedFocus?(editor, range)
    }

    func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange) {
        onLostFocus?(editor, range)
    }

    func editor(_ editor: EditorView, didExecuteProcessors processors: [TextProcessing], at range: NSRange) {
        onDidExecuteProcessors?(editor, processors, range)
    }
}
