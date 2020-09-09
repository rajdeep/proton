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
    static let defaultListLineFormatting = LineFormatting(indentation: 25, spacingBefore: 0)

    weak var richTextViewDelegate: RichTextViewDelegate?
    weak var richTextViewListDelegate: RichTextViewListDelegate?

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

            if let range = adjustedTextBlockRangeOnSelectionChange(oldRange: old, newRange: new) {
                selectedRange = range
            }
            richTextViewDelegate?.richTextView(self, selectedRangeChangedFrom: old, to: selectedTextRange?.toNSRange(in: self))
        }
    }

    private func adjustedTextBlockRangeOnSelectionChange(oldRange: NSRange?, newRange: NSRange?) -> NSRange? {
        guard let old = oldRange,
            let new = newRange,
            old != new else { return nil }

        let isReverseTraversal = (new.location < old.location) || (new.endLocation < old.endLocation)

        guard new.length > 0 else {
            if let textBlockRange = attributedText.rangeOf(attribute: .textBlock, at: new.location),
                textBlockRange.location != new.location {
                let location = isReverseTraversal ? textBlockRange.location : textBlockRange.endLocation
                return NSRange(location: location, length: 0)
            }
            return nil
        }

        let isLocationChanged = new.location != old.location
        let location = isLocationChanged ? new.location : max(0, new.endLocation - 1)

        guard let textBlockRange = attributedText.rangeOf(attribute: .textBlock, at: location),
            textBlockRange.contains(location) else {
                return nil
        }

        if isReverseTraversal {
            return adjustedTextBlockRangeReverse(new: new, old: old, textBlockRange: textBlockRange)
        } else {
            return adjustedTextBlockRangeForward(new: new, old: old, textBlockRange: textBlockRange)
        }
    }

    private func adjustedTextBlockRangeReverse(new: NSRange, old: NSRange, textBlockRange: NSRange) -> NSRange {
        let range: NSRange
        if textBlockRange.union(new) == textBlockRange && new.endLocation == old.endLocation && textBlockRange.contains(new.location) == false {
            range = NSRange(location: textBlockRange.location, length: old.endLocation - textBlockRange.endLocation)
        } else if new.endLocation < textBlockRange.endLocation && new.endLocation > textBlockRange.location {
            range = NSRange(location: new.location, length: textBlockRange.location - new.location)
        } else {
            range = textBlockRange.union(new)
        }
        return range
    }

    private func adjustedTextBlockRangeForward(new: NSRange, old: NSRange, textBlockRange: NSRange) -> NSRange {
        let range: NSRange
        let isLocationChanged = new.location != old.location
        if (new.contains(textBlockRange.location) && new.contains(textBlockRange.endLocation - 1)
            || (textBlockRange.union(new) == textBlockRange && new.length > 0 && isLocationChanged == false)
            || isLocationChanged == false) {
            range = new.union(textBlockRange)
        } else {
            range = NSRange(location: textBlockRange.endLocation, length: new.endLocation - textBlockRange.endLocation)
        }
        return range
    }

    private func adjustRangeOnNonFocus(oldRange: UITextRange?) {
        guard let currentRange = selectedTextRange?.toNSRange(in: self),
            let previousRange = oldRange?.toNSRange(in: self) else { return }

        var rangeToSet: NSRange?
        let isReverseTraversal = currentRange.location < previousRange.location
        var rangeToTraverse = NSRange(location: currentRange.location, length: attributedText.length - (currentRange.location + currentRange.length))

        if isReverseTraversal == true {
            rangeToTraverse = NSRange(location: 0, length: currentRange.location)
            attributedText.enumerateAttribute(.textBlock, in: rangeToTraverse, options: [.longestEffectiveRangeNotRequired, .reverse]) { val, range, stop in
                if (val as? Bool != true), rangeToSet == nil {
                    rangeToSet = NSRange(location: range.location + range.length, length: 0)
                    stop.pointee = true
                }
            }
        }  else {
            attributedText.enumerateAttribute(.textBlock, in: rangeToTraverse, options: [.longestEffectiveRangeNotRequired]) { val, range, stop in
                if (val as? Bool != true), rangeToSet == nil {
                    rangeToSet = NSRange(location: range.location, length: 0)
                    stop.pointee = true
                }
            }
        }

        selectedTextRange = rangeToSet?.toTextRange(textInput: self) ?? oldRange
    }

    init(frame: CGRect = .zero, context: RichTextViewContext, allowAutogrowing: Bool = false) {
        let textContainer = TextContainer()
        let layoutManager = LayoutManager()

        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: textContainer, allowAutogrowing: allowAutogrowing)
        layoutManager.delegate = self
        layoutManager.layoutManagerDelegate = self
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

    func contentLinesInRange(_ range: NSRange) -> [EditorLine] {
        var lines = [EditorLine]()

        var startingRange = NSRange(location: range.location, length: 0)
        let endLocation = max(startingRange.location, range.location + range.length - 1)

        while startingRange.location <= endLocation {
            let paraRange = rangeOfParagraph(at: startingRange.location)
            let text = self.attributedText.attributedSubstring(from: paraRange)
            let editorLine = EditorLine(text: text, range: paraRange)
            lines.append(editorLine)
            startingRange = NSRange(location: paraRange.length + paraRange.location + 1, length: 0)
        }

        return lines
    }

    func rangeOfParagraph(at location: Int) -> NSRange {
        guard let position = self.position(from: beginningOfDocument, offset: location),
            let paraRange = tokenizer.rangeEnclosingPosition(position, with: .paragraph, inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)),
            let range = paraRange.toNSRange(in: self) else {
                return NSRange(location: location, length: 0)
        }
        return range
    }

    func previousContentLine(from location: Int) -> EditorLine? {
        let currentLineRange = rangeOfParagraph(at: location)
        guard let position = self.position(from: beginningOfDocument, offset: currentLineRange.location - 1),
            let paraRange = tokenizer.rangeEnclosingPosition(position, with: .paragraph, inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)),
            let range = paraRange.toNSRange(in: self) else {
                return nil
        }
        return EditorLine(text: attributedText.attributedSubstring(from: range), range: range)
    }

    func nextContentLine(from location: Int) -> EditorLine? {
        let currentLineRange = rangeOfParagraph(at: location)
        guard let position = self.position(from: beginningOfDocument, offset: currentLineRange.endLocation + 1),
            let paraRange = tokenizer.rangeEnclosingPosition(position, with: .paragraph, inDirection: UITextDirection(rawValue: UITextStorageDirection.forward.rawValue)),
            let range = paraRange.toNSRange(in: self) else {
                return nil
        }
        return EditorLine(text: attributedText.attributedSubstring(from: range), range: range)
    }

    override var keyCommands: [UIKeyCommand]? {
        let tab = "\t"
        let enter = "\r"

        return [
            UIKeyCommand(input: tab, modifierFlags: [], action: #selector(handleKeyCommand(command:))),
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

        richTextViewDelegate?.richTextView(self, didReceive: key, modifierFlags: modifierFlags, at: selectedRange)
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
        defer {
            if contentLength == 0 {
                self.typingAttributes = defaultTypingAttributes
            }
            richTextViewDelegate?.richTextView(self, didReceive: .backspace, modifierFlags: [], at: selectedRange)
        }

        guard contentLength > 0 else { return }
        let proposedRange = NSRange(location: max(0, selectedRange.location - 1), length: 0)

        let attributeExists = (attributedText.attribute(.textBlock, at: proposedRange.location, effectiveRange: nil) as? Bool) == true

        guard attributeExists, let textRange = adjustedTextBlockRangeOnSelectionChange(oldRange: selectedRange, newRange: proposedRange) else {
            super.deleteBackward()
            return
        }

        let rangeToDelete = NSRange(location: textRange.location, length: selectedRange.location - textRange.location)
        replaceCharacters(in: rangeToDelete, with: NSAttributedString())
        selectedRange = NSRange(location: textRange.location, length: 0)
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
        guard self.attributedText.length == 0 else {
            placeholderLabel.removeFromSuperview()
            return
        }
        setupPlaceholder()
    }

    func attributeValue(at location: CGPoint, for attribute: NSAttributedString.Key) -> Any? {
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textStorage.length else {
            return nil
        }

        let attributes = textStorage.attributes(at: characterIndex, longestEffectiveRange: nil, in: textStorage.fullRange)
        return attributes[attribute]
    }

    func glyphRange(forCharacterRange range: NSRange) -> NSRange {
        return layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
    }

    func boundingRect(forGlyphRange range: NSRange) -> CGRect {
        return layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
    }

    func contents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.attributedText.enumerateContents(in: range)
    }

    func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        storage.setAttributes(attrs, range: range)
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

    func didTap(at location: CGPoint) {
        let characterRange = rangeOfCharacter(at: location)
        richTextViewDelegate?.richTextView(self, didTapAtLocation: location, characterRange: characterRange)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self)
            didTap(at: position)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard editorView?.canPerformMenuAction(action, withSender: sender) == true else {
            return false
        }

        return super.canPerformAction(action, withSender: sender)
    }

    override func copy(_ sender: Any?) {
        if editorView?.responds(to: #selector(copy(_:))) ?? false {
            editorView?.copy(sender)
        } else {
            super.copy(sender)
        }
    }

    override func paste(_ sender: Any?) {
        if editorView?.responds(to: #selector(paste(_:))) ?? false {
            editorView?.paste(sender)
        } else {
            super.paste(sender)
        }
    }

    override func cut(_ sender: Any?) {
        if editorView?.responds(to: #selector(cut)) ?? false {
            editorView?.cut(sender)
        } else {
            super.cut(sender)
        }
    }

    override func select(_ sender: Any?) {
        if editorView?.responds(to: #selector(select)) ?? false {
            editorView?.select(sender)
        } else {
            super.select(sender)
        }
    }

    override func selectAll(_ sender: Any?) {
        if editorView?.responds(to: #selector(selectAll)) ?? false {
            editorView?.selectAll(sender)
        } else {
            super.selectAll(sender)
        }
    }

    override func toggleUnderline(_ sender: Any?) {
        if editorView?.responds(to: #selector(toggleUnderline)) ?? false {
            editorView?.toggleUnderline(sender)
        } else {
            super.toggleUnderline(sender)
        }
    }

    override func toggleItalics(_ sender: Any?) {
        if editorView?.responds(to: #selector(toggleItalics)) ?? false {
            editorView?.toggleItalics(sender)
        } else {
            super.toggleItalics(sender)
        }
    }

    override func toggleBoldface(_ sender: Any?) {
        if editorView?.responds(to: #selector(toggleBoldface)) ?? false {
            editorView?.toggleBoldface(sender)
        } else {
            super.toggleBoldface(sender)
        }
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        let location = offset(from: beginningOfDocument, to: position)
        let lineRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: location, length: 0), in: textContainer)

        var caretRect = super.caretRect(for: position)
        caretRect.origin.y = lineRect.minY + textContainerInset.top
        caretRect.size.height = lineRect.height
        return caretRect
    }
    
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        let firstCharacterRect = caretRect(for: range.start)
        let lastCharacterRect = caretRect(for: range.end)

        return super.selectionRects(for: range).map { selectionRect -> UITextSelectionRect in
            if selectionRect.containsStart {
                return TextSelectionRect(selection: selectionRect, caretRect: firstCharacterRect)
            } else if selectionRect.containsEnd {
                return TextSelectionRect(selection: selectionRect, caretRect: lastCharacterRect)
            } else {
                return selectionRect
            }
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

extension RichTextView: LayoutManagerDelegate {
    var listLineFormatting: LineFormatting {
        return richTextViewListDelegate?.listLineFormatting ?? RichTextView.defaultListLineFormatting
    }

    var paragraphStyle: NSMutableParagraphStyle? {
        return defaultTextFormattingProvider?.paragraphStyle
    }

    func listMarkerForItem(at index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let defaultValue = NSAttributedString(string: "*", attributes: [.font: font])
        return richTextViewListDelegate?.richTextView(self, listMarkerForItemAt: index, level: level, previousLevel: previousLevel, attributeValue: attributeValue) ?? .string(defaultValue)
    }
}

private final class TextSelectionRect: UITextSelectionRect {
    override var rect: CGRect { _rect }
    override var writingDirection: NSWritingDirection { _writingDirection }
    override var containsStart: Bool { _containsStart }
    override var containsEnd: Bool { _containsEnd }
    override var isVertical: Bool { _isVertical }

    private let _rect: CGRect
    private let _writingDirection: NSWritingDirection
    private let _containsStart: Bool
    private let _containsEnd: Bool
    private let _isVertical: Bool

    init(selection: UITextSelectionRect, caretRect: CGRect) {
        self._rect = .init(x: selection.rect.minX, y: caretRect.minY, width: selection.rect.width, height: caretRect.height)
        self._writingDirection = selection.writingDirection
        self._containsStart = selection.containsStart
        self._containsEnd = selection.containsEnd
        self._isVertical = selection.isVertical
    }
}
