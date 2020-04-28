//
//  RichTextView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
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

class RichTextView: AutogrowingTextView {
    private let storage = TextStorage()

    weak var richTextViewDelegate: RichTextViewDelegate?

    weak var defaultTextFormattingProvider: DefaultTextFormattingProviding? {
        get { storage.defaultTextFormattingProvider }
        set { storage.defaultTextFormattingProvider = newValue }
    }

    private let placeholderLabel = UILabel()

    var placeholderText: NSAttributedString? {
        didSet {
            placeholderLabel.attributedText = placeholderText
        }
    }

    weak var menuDelegate: MenuDelegate?

    var editorView: EditorView? {
        return superview as? EditorView
    }

    var defaultTypingAttributes: RichTextAttributes {
        return [
            .font: defaultTextFormattingProvider?.font ?? storage.defaultFont,
            .paragraphStyle: defaultTextFormattingProvider?.paragraphStyle ?? storage.defaultParagraphStyle,
            .foregroundColor: defaultTextFormattingProvider?.textColor ?? storage.defaultTextColor
        ]
    }
    var defaultTextColor: UIColor { storage.defaultTextColor }
    var defaultBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }

    override var selectedTextRange: UITextRange? {
        didSet{
            let old = oldValue?.toNSRange(in: self)
            let new = selectedTextRange?.toNSRange(in: self)

            // Handle the case where caret is moved using keys or direct taps on given location.
            // When selecting text or using backspace/delete, this code is skipped
            if oldValue != selectedTextRange,
                let new = new, new.length <= 1,
                new.location < attributedText.length - 1 {

                let newTextRange = attributedText.attributedSubstring(from: NSRange(location: new.location, length: 1))
                let isNonFocus = newTextRange.attribute(.noFocus, at: 0, effectiveRange: nil) as? Bool == true

                if isNonFocus == true {
                    adjustRangeOnNonFocus(oldRange: oldValue)
                }
            }
            richTextViewDelegate?.richTextView(self, selectedRangeChangedFrom: old, to: new)
        }
    }

    private func adjustRangeOnNonFocus(oldRange: UITextRange?) {
        guard let currentRange = selectedTextRange?.toNSRange(in: self),
            let previousRange = oldRange?.toNSRange(in: self) else { return }

        var rangeToSet: NSRange?
        let isReverseTraversal = currentRange.location < previousRange.location
        var rangeToTraverse = NSRange(location: currentRange.location, length: attributedText.length - (currentRange.location + currentRange.length))

        if isReverseTraversal == true {
            rangeToTraverse = NSRange(location: 0, length: currentRange.location)
            attributedText.enumerateAttribute(.noFocus, in: rangeToTraverse, options: [.longestEffectiveRangeNotRequired, .reverse]) { val, range, stop in
                if (val as? Bool != true), rangeToSet == nil {
                    rangeToSet = NSRange(location: range.location + range.length, length: 0)
                    stop.pointee = true
                }
            }
        }  else {
            attributedText.enumerateAttribute(.noFocus, in: rangeToTraverse, options: [.longestEffectiveRangeNotRequired]) { val, range, stop in
                if (val as? Bool != true), rangeToSet == nil {
                    rangeToSet = NSRange(location: range.location, length: 0)
                    stop.pointee = true
                }
            }
        }

        selectedTextRange = rangeToSet?.toTextRange(textInput: self) ?? oldRange
    }

    init(frame: CGRect = .zero, context: RichTextViewContext, growsInfinitely: Bool) {
        let textContainer = TextContainer()
        let layoutManager = NSLayoutManager()

        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: textContainer, growsInfinitely: growsInfinitely)
        layoutManager.delegate = self
        textContainer.textView = self
        self.delegate = context
        storage.textStorageDelegate = self

        self.backgroundColor = defaultBackgroundColor
        self.textColor = defaultTextColor

        setupPlaceholder()
    }

    var richTextStorage: TextStorage {
        return storage
    }

    var contentLength: Int {
        return storage.length
    }

    weak var textProcessor: TextProcessor? {
        didSet {
            storage.delegate = textProcessor
        }
    }

    var textEndRange: NSRange {
        return storage.textEndRange
    }

    var currentLineRange: NSRange? {
        return lineRange(from: selectedRange.location)
    }

    var visibleRange: NSRange {
        let textBounds = bounds.inset(by: textContainerInset)
        return layoutManager.glyphRange(forBoundingRect: textBounds, in: textContainer)
    }

    override var keyCommands: [UIKeyCommand]? {
        let tab = "\t"
        let enter = "\r"

        return [
            UIKeyCommand(input: tab, modifierFlags: .shift, action: #selector(handleKeyCommand(command:))),
            UIKeyCommand(input: enter, modifierFlags: .shift, action: #selector(handleKeyCommand(command:))),
            UIKeyCommand(input: enter, modifierFlags: .control, action: #selector(handleKeyCommand(command:))),
            UIKeyCommand(input: enter, modifierFlags: .alternate, action: #selector(handleKeyCommand(command:))),
        ]
    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if targetEnvironment(macCatalyst)
    @objc(_focusRingType)
    var focusRingType: UInt {
        return 1 //NSFocusRingTypeNone
    }
    #endif

    @objc
    func handleKeyCommand(command: UIKeyCommand) {
        guard let input = command.input,
            let key = EditorKey(input) else { return }
        
        let modifierFlags = command.modifierFlags
        var handled = false
        richTextViewDelegate?.richTextView(self, didReceiveKey: key, modifierFlags: modifierFlags, at: selectedRange, handled: &handled)
    }

    private func setupPlaceholder() {
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.numberOfLines = 0
        placeholderLabel.lineBreakMode = .byTruncatingTail

        addSubview(placeholderLabel)
        placeholderLabel.attributedText = placeholderText
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: textContainerInset.top),
            placeholderLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -textContainerInset.bottom),
            placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: textContainer.lineFragmentPadding),
            placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -textContainer.lineFragmentPadding),
            placeholderLabel.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -textContainer.lineFragmentPadding)
        ])
    }

    func wordAt(_ location: Int) -> NSAttributedString? {
        guard let position = self.position(from: beginningOfDocument, offset: location),
            let wordRange = tokenizer.rangeEnclosingPosition(position, with: .word, inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)),
            let range = wordRange.toNSRange(in: self) else {
                return nil
        }
        return attributedText.attributedSubstring(from: range)
    }

    func lineRange(from location: Int) -> NSRange? {
        var currentLocation = location
        guard contentLength > 0 else { return .zero }
        var range = NSRange()
        // In case this is called before layout has completed, e.g. from TextProcessor, the last entered glyph
        // will not have been laid out by layoutManager but would be present in TextStorage. It can also happen
        // when deleting multiple characters where layout is pending in the same case. Following logic finds the
        // last valid glyph that is already laid out.
        while currentLocation > 0 && layoutManager.isValidGlyphIndex(currentLocation) == false {
            currentLocation -= 1
        }
        guard layoutManager.isValidGlyphIndex(currentLocation) else { return NSRange(location: 0, length: 1) }
        layoutManager.lineFragmentUsedRect(forGlyphAt: currentLocation, effectiveRange: &range)
        guard range.location != NSNotFound else { return nil }
        // As mentioned above, in case of this getting called before layout is completed,
        // we need to account for the range that has been changed. storage.changeInLength provides
        // the change that might not have been laid already
        return NSRange(location: range.location, length: range.length + storage.changeInLength)
    }

    func invalidateLayout(for range: NSRange) {
        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
    }

    func invalidateDisplay(for range: NSRange) {
        layoutManager.invalidateDisplay(forCharacterRange: range)
    }

    override func deleteBackward() {
        super.deleteBackward()
        guard contentLength == 0 else {
            return
        }
        self.typingAttributes = defaultTypingAttributes
    }

    func insertAttachment(in range: NSRange, attachment: Attachment) {
        richTextStorage.insertAttachment(in: range, attachment: attachment)
        if let rangeInContainer = attachment.rangeInContainer() {
            edited(range: rangeInContainer)
        }
        scrollRangeToVisible(NSRange(location: range.location, length: 1))
    }

    func edited(range: NSRange) {
        richTextStorage.beginEditing()
        richTextStorage.edited([.editedCharacters, .editedAttributes], range: range, changeInLength: 0)
        richTextStorage.endEditing()
    }

    func transformContents<T: EditorContentEncoding>(in range: NSRange? = nil, using transformer: T) -> [T.EncodedType] {
        return contents(in: range).compactMap(transformer.encode)
    }

    func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        richTextStorage.replaceCharacters(in: range, with: attrString)
        updatePlaceholderVisibility()
    }

    func replaceCharacters(in range: NSRange, with string: String) {
        // Delegate to function with attrString so that default attributes are automatically applied
        richTextStorage.replaceCharacters(in: range, with: NSAttributedString(string: string))
    }

    private func updatePlaceholderVisibility() {
        self.placeholderLabel.attributedText = self.attributedText.length == 0 ? self.placeholderText : NSAttributedString()
    }

    func attributeValue(at location: CGPoint, for attribute: NSAttributedString.Key) -> Any? {
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textStorage.length else {
            return nil
        }

        let attributes = textStorage.attributes(at: characterIndex, longestEffectiveRange: nil, in: textStorage.fullRange)
        return attributes[attribute]
    }

    func boundingRect(forGlyphRange range: NSRange) -> CGRect {
        return layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
    }

    func contents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.attributedText.enumerateContents(in: range)
    }

    func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        storage.addAttributes(attrs, range: range)
    }

    func removeAttributes(_ attrs: [NSAttributedString.Key], range: NSRange) {
        storage.removeAttributes(attrs, range: range)
    }

    func enumerateAttribute(_ attrName: NSAttributedString.Key, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        storage.enumerateAttribute(attrName, in: enumerationRange, options: opts, using: block)
    }

    func rangeOfCharacter(at point: CGPoint) -> NSRange? {
        return characterRange(at: point)?.toNSRange(in: self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self)
            didTap(at: position)
        }
    }

    func didTap(at location: CGPoint) {
        let characterRange = rangeOfCharacter(at: location)
        richTextViewDelegate?.richTextView(self, didTapAtLocation: location, characterRange: characterRange)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return menuDelegate?.canPerformDefaultAction(action, withSender: sender) == true
            && super.responds(to: action)
            && super.canPerformAction(action, withSender: sender)
    }

    override func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        super.perform(aSelector)
    }

    override func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        if menuDelegate?.responds(to: aSelector) == true {
            return menuDelegate?.perform(aSelector, with: object)
        } else {
            return super.perform(aSelector, with: object)
        }
    }

}

extension RichTextView: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        updatePlaceholderVisibility()
        richTextViewDelegate?.richTextView(self, didFinishLayout: layoutFinishedFlag)
    }
}

extension RichTextView: TextStorageDelegate {
    func textStorage(_ textStorage: TextStorage, willDeleteText deletedText: NSAttributedString, insertedText: NSAttributedString, range: NSRange) {
        textProcessor?.textStorage(textStorage, willProcessDeletedText: deletedText, insertedText: insertedText)
    }
}
