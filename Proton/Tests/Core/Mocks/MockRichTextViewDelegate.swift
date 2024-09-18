//
//  MockRichTextViewDelegate.swift
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
import UIKit

@testable import Proton

class MockRichTextViewDelegate: RichTextViewDelegate {
    var onSelectionChanged: ((RichTextView, NSRange, [NSAttributedString.Key: Any], EditorContent.Name) -> Void)?
    var onShouldHandleKey: ((RichTextView, EditorKey, UIKeyModifierFlags, NSRange, Bool) -> Void)?
    var onDidReceiveKey: ((RichTextView, EditorKey, UIKeyModifierFlags, NSRange) -> Void)?
    var onReceivedFocus: ((RichTextView, NSRange) -> Void)?
    var onLostFocus: ((RichTextView, NSRange) -> Void)?
    var onDidChangeText: ((RichTextView, NSRange) -> Void)?
    var onDidFinishLayout: ((RichTextView, Bool) -> Void)?
    var onDidTapAtLocation: ((RichTextView, CGPoint, NSRange?) -> Void)?
    var onSelectedRangeChanged: ((RichTextView, NSRange?, NSRange?) -> Void)?
    var onShouldSelectAttachmentOnBackspace: ((RichTextView, Attachment) -> Bool)?
    var onDidChangeScrollEnabled: ((RichTextView, Bool) -> Void)?

    func richTextView(_ richTextView: RichTextView, didChangeSelection range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        onSelectionChanged?(richTextView, range, attributes, contentType)
    }

    func richTextView(_ richTextView: RichTextView, shouldHandle key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange, handled: inout Bool) {
        onShouldHandleKey?(richTextView, key, modifierFlags, range, handled)
    }

    func richTextView(_ richTextView: RichTextView, didReceive key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange) {
        onDidReceiveKey?(richTextView, key, modifierFlags, range)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange) {
        onReceivedFocus?(richTextView, range)
    }

    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange) {
        onLostFocus?(richTextView, range)
    }

    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool) {
        onDidFinishLayout?(richTextView, finished)
    }

    func richTextView(_ richTextView: RichTextView, didChangeTextAtRange range: NSRange) {
        onDidChangeText?(richTextView, range)
    }

    func richTextView(_ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        onDidTapAtLocation?(richTextView, location, characterRange)
    }

    func richTextView(_ richTextView: RichTextView, selectedRangeChangedFrom oldRange: NSRange?, to newRange: NSRange?) {
        onSelectedRangeChanged?(richTextView, oldRange, newRange)
    }

    func richTextView(_ richTextView: RichTextView, shouldSelectAttachmentOnBackspace attachment: Attachment) -> Bool? {
        onShouldSelectAttachmentOnBackspace?(richTextView, attachment) ?? false
    }

    func richTextView(_ richTextView: RichTextView, didChangeScrollEnabled isScrollEnabled: Bool) {
        onDidChangeScrollEnabled?(richTextView, isScrollEnabled)
    }
}
