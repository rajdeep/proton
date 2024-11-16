//
//  EditorView+UITextInput.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 16/11/2024.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
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

extension EditorView: UITextInput {
    public func text(in range: UITextRange) -> String? {
        richTextView.text(in: range)
    }
    
    public func replace(_ range: UITextRange, withText text: String) {
        richTextView.replace(range, withText: text)
    }
    
    public var markedTextRange: UITextRange? {
        richTextView.markedTextRange
    }

    public var markedTextStyle: [NSAttributedString.Key : Any]? {
        get {
            richTextView.markedTextStyle
        }
        set(markedTextStyle) {
            richTextView.markedTextStyle = markedTextStyle
        }
    }
    
    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        richTextView.setMarkedText(markedText, selectedRange: selectedRange)
    }
    
    public func unmarkText() {
        richTextView.unmarkText()
    }
    
    public var beginningOfDocument: UITextPosition {
        richTextView.beginningOfDocument
    }
    
    public var endOfDocument: UITextPosition {
        richTextView.endOfDocument
    }
    
    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        richTextView.textRange(from: fromPosition, to: toPosition)
    }
    
    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        richTextView.position(from: position, offset: offset)
    }
    
    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        richTextView.position(from: position, in: direction, offset: offset)
    }
    
    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        richTextView.compare(position, to: other)
    }
    
    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        richTextView.offset(from: from, to: toPosition)
    }
    
    public var inputDelegate: (any UITextInputDelegate)? {
        get {
            richTextView.inputDelegate
        }
        set(inputDelegate) {
            richTextView.inputDelegate = inputDelegate
        }
    }
    
    public var tokenizer: any UITextInputTokenizer {
        richTextView.tokenizer
    }
    
    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        richTextView.position(within: range, farthestIn: direction)
    }
    
    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        richTextView.characterRange(byExtending: position, in: direction)
    }
    
    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        richTextView.baseWritingDirection(for: position, in: direction)
    }
    
    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        richTextView.setBaseWritingDirection(writingDirection, for: range)
    }
    
    public func firstRect(for range: UITextRange) -> CGRect {
        richTextView.firstRect(for: range)
    }
    
    public func caretRect(for position: UITextPosition) -> CGRect {
        richTextView.caretRect(for: position)
    }
    
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        richTextView.selectionRects(for: range)
    }
    
    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        richTextView.closestPosition(to: point)
    }
    
    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        richTextView.closestPosition(to: point, within: range)
    }
    
    public func characterRange(at point: CGPoint) -> UITextRange? {
        richTextView.characterRange(at: point)
    }
    
    public var hasText: Bool {
        richTextView.hasText
    }
    
    public func insertText(_ text: String) {
        richTextView.insertText(text)
    }
}

@propertyWrapper
struct RichTextViewProperty<T> {
    private weak var textView: RichTextView?
    private let keyPath: ReferenceWritableKeyPath<UITextView, T>

    init(_ textView: RichTextView, keyPath: ReferenceWritableKeyPath<UITextView, T>) {
        self.textView = textView
        self.keyPath = keyPath
    }

    var wrappedValue: T {
        get {
            return textView?[keyPath: keyPath] ?? (T.self as! T)
        }
        set {
            textView?[keyPath: keyPath] = newValue
        }
    }
}
