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
import ProtonCore
import CoreGraphics

class RichTextView: AutogrowingTextView {
    
    /// Equivalent, strongly-typed alternative to `textStorage`
    private let richTextStorage = PRTextStorage()
    static let defaultListLineFormatting = LineFormatting(indentation: 25, spacingBefore: 0)

    weak var richTextViewDelegate: RichTextViewDelegate?
    weak var richTextViewListDelegate: RichTextViewListDelegate?

    weak var defaultTextFormattingProvider: DefaultTextFormattingProviding?
    {
        get { richTextStorage.defaultTextFormattingProvider }
        set { richTextStorage.defaultTextFormattingProvider = newValue }
    }

    private let placeholderLabel = PlatformLabel()

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
            .font: defaultTextFormattingProvider?.font ?? richTextStorage.defaultFont,
            .paragraphStyle: defaultTextFormattingProvider?.paragraphStyle ?? richTextStorage.defaultParagraphStyle,
            .foregroundColor: defaultTextFormattingProvider?.textColor ?? richTextStorage.defaultTextColor
        ]
    }
    var defaultFont: PlatformFont { richTextStorage.defaultFont }
    var defaultTextColor: PlatformColor { richTextStorage.defaultTextColor }
    var defaultBackgroundColor: PlatformColor {
        #if os(iOS)
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
        #else
        return .systemBackground
        #endif
    }

    #if os(iOS)
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
    #else
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        let old = selectedRange()
        let new = charRange

        var adjustedRange = new
        if let range = adjustedTextBlockRangeOnSelectionChange(oldRange: old, newRange: new) {
            adjustedRange = range
        }
        
        super.setSelectedRange(adjustedRange, affinity: affinity, stillSelecting: stillSelectingFlag)
        
        richTextViewDelegate?.richTextView(self, selectedRangeChangedFrom: old, to: selectedRange())
    }
    #endif

    private func adjustedTextBlockRangeOnSelectionChange(oldRange: NSRange?, newRange: NSRange?) -> NSRange? {
        guard let old = oldRange,
              let new = newRange,
              old != new
        else { return nil }

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
              textBlockRange.contains(location)
        else { return nil }

        if isReverseTraversal {
            return adjustedTextBlockRangeReverse(new: new, old: old, textBlockRange: textBlockRange)
        } else {
            return adjustedTextBlockRangeForward(new: new, old: old, textBlockRange: textBlockRange)
        }
    }

    private func adjustedTextBlockRangeReverse(new: NSRange, old: NSRange, textBlockRange: NSRange) -> NSRange {
        let range: NSRange
        if textBlockRange.union(new) == textBlockRange, new.endLocation == old.endLocation, textBlockRange.contains(new.location) == false {
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

    #if os(iOS)
    private func adjustRangeOnNonFocus(oldRange: UITextRange?) {
        guard let currentRange = selectedTextRange?.toNSRange(in: self),
              let previousRange = oldRange?.toNSRange(in: self)
        else { return }

        var rangeToSet: NSRange?
        let isReverseTraversal = currentRange.location < previousRange.location
        var rangeToTraverse = NSRange(location: currentRange.location, length: attributedText.length - (currentRange.location + currentRange.length))

        if isReverseTraversal {
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
    #endif

    init(frame: CGRect = .zero, context: RichTextViewContext) {
        let textContainer = TextContainer()
        let layoutManager = LayoutManager()

        layoutManager.addTextContainer(textContainer)
        richTextStorage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: textContainer)
        layoutManager.delegate = self
        layoutManager.layoutManagerDelegate = self
        #if os(iOS)
        textContainer.textView = self
        self.delegate = context
        #else
        self.nsDelegateBridge = context
        #endif
        
        richTextStorage.textStorageDelegate = self

        self.backgroundColor = defaultBackgroundColor
        self.textColor = defaultTextColor

        setupPlaceholder()
    }

    var contentLength: Int {
        return nsTextStorage.length
    }

    weak var textProcessor: TextProcessor? {
        didSet {
            richTextStorage.delegate = textProcessor
        }
    }

    var textEndRange: NSRange {
        return NSRange(location: contentLength, length: 0)
    }

    var currentLineRange: NSRange? {
        return lineRange(from: selectedRange.location)
    }

    var visibleRange: NSRange {
        let textBounds = bounds.inset(by: textContainerEdgeInset)
        return nsLayoutManager.glyphRange(forBoundingRect: textBounds, in: nsTextContainer)
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
        #if os(iOS)
        guard let position = self.position(from: beginningOfDocument, offset: location),
              let paraRange = tokenizer.rangeEnclosingPosition(position, with: .paragraph, inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)),
              let range = paraRange.toNSRange(in: self)
        else {
            return NSRange(location: location, length: 0)
        }
        return range
        #else
        // TODO: Implement on macOS
        fatalError()
        #endif
    }

    func previousContentLine(from location: Int) -> EditorLine? {
        #if os(iOS)
        let currentLineRange = rangeOfParagraph(at: location)
        guard let position = self.position(from: beginningOfDocument, offset: currentLineRange.location - 1),
              let paraRange = tokenizer.rangeEnclosingPosition(position, with: .paragraph, inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)),
              let range = paraRange.toNSRange(in: self)
        else { return nil }
        
        return EditorLine(text: attributedText.attributedSubstring(from: range), range: range)
        #else
        // TODO: Implement on macOS
        fatalError()
        #endif
    }

    func nextContentLine(from location: Int) -> EditorLine? {
        #if os(iOS)
        let currentLineRange = rangeOfParagraph(at: location)
        guard let position = self.position(from: beginningOfDocument, offset: currentLineRange.endLocation + 1),
              let paraRange = tokenizer.rangeEnclosingPosition(position, with: .paragraph, inDirection: UITextDirection(rawValue: UITextStorageDirection.forward.rawValue)),
              let range = paraRange.toNSRange(in: self)
        else { return nil }
        
        return EditorLine(text: attributedText.attributedSubstring(from: range), range: range)
        #else
        // TODO: Implement on macOS
        fatalError()
        #endif
    }

    #if os(iOS)
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
    #endif

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

    #if os(iOS)
    @objc
    func handleKeyCommand(command: UIKeyCommand) {
        guard let input = command.input,
              let key = EditorKey(input)
        else { return }
        
        let modifierFlags = command.modifierFlags

        richTextViewDelegate?.richTextView(self, didReceive: key, modifierFlags: modifierFlags, at: selectedRange)
    }
    #endif

    private func setupPlaceholder() {
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.numberOfLines = 0
        placeholderLabel.lineBreakMode = .byTruncatingTail

        addSubview(placeholderLabel)
        placeholderLabel.attributedText = placeholderText
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: textContainerEdgeInset.top),
            placeholderLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -textContainerEdgeInset.bottom),
            placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: nsTextContainer.lineFragmentPadding),
            placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -nsTextContainer.lineFragmentPadding),
        ])
    }

    func wordAt(_ location: Int) -> NSAttributedString? {
        #if os(iOS)
        guard let position = self.position(from: beginningOfDocument, offset: location),
              let wordRange = tokenizer.rangeEnclosingPosition(position, with: .word, inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)),
              let range = wordRange.toNSRange(in: self)
        else { return nil }
        
        return attributedText.attributedSubstring(from: range)
        #else
        // TODO: Implement on macOS
        fatalError()
        #endif
    }

    func lineRange(from location: Int) -> NSRange? {
        var currentLocation = location
        guard contentLength > 0 else { return .zero }
        var range = NSRange()
        // In case this is called before layout has completed, e.g. from TextProcessor, the last entered glyph
        // will not have been laid out by layoutManager but would be present in TextStorage. It can also happen
        // when deleting multiple characters where layout is pending in the same case. Following logic finds the
        // last valid glyph that is already laid out.
        while currentLocation > 0 && nsLayoutManager.isValidGlyphIndex(currentLocation) == false {
            currentLocation -= 1
        }
        guard nsLayoutManager.isValidGlyphIndex(currentLocation) else { return NSRange(location: 0, length: 1) }
        nsLayoutManager.lineFragmentUsedRect(forGlyphAt: currentLocation, effectiveRange: &range)
        guard range.location != NSNotFound else { return nil }
        // As mentioned above, in case of this getting called before layout is completed,
        // we need to account for the range that has been changed. storage.changeInLength provides
        // the change that might not have been laid already
        return NSRange(location: range.location, length: range.length + nsTextStorage.changeInLength)
    }

    func invalidateLayout(for range: NSRange) {
        nsLayoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
    }

    func invalidateDisplay(for range: NSRange) {
        nsLayoutManager.invalidateDisplay(forCharacterRange: range)
    }

    func resetTypingAttributes() {
        self.typingAttributes = defaultTypingAttributes
    }

    override func deleteBackward() {
        defer {
            if contentLength == 0 {
                resetTypingAttributes()
            }
            richTextViewDelegate?.richTextView(self, didReceive: .backspace, modifierFlags: [], at: selectedRange)
        }

        guard contentLength > 0 else { return }
        let proposedRange = NSRange(location: max(0, selectedRange.location - 1), length: 0)

        let attributedText: NSAttributedString = self.attributedText // single allocation
        let attributeExists = (attributedText.attribute(.textBlock, at: proposedRange.location, effectiveRange: nil) as? Bool) == true

        guard attributeExists,
              let textRange = adjustedTextBlockRangeOnSelectionChange(oldRange: selectedRange, newRange: proposedRange)
        else {
            // if the character getting deleted is a list item spacer, do a double delete
            let textToBeDeleted = attributedText.substring(from: NSRange(location: proposedRange.location, length: 1))
            if textToBeDeleted == ListTextProcessor.blankLineFiller {
                super.deleteBackward()
            }
            super.deleteBackward()
            return
        }

        let rangeToDelete = NSRange(location: textRange.location, length: selectedRange.location - textRange.location)
        replaceCharacters(in: rangeToDelete, with: NSAttributedString())
        selectedRange = NSRange(location: textRange.location, length: 0)
    }

    func insertAttachment(in range: NSRange, attachment: Attachment) {
        richTextStorage.insertAttachment(in: range, attachment: attachment, withSpacer: attachment.spacer)
        // TODO: Temporary workaround to get around the issue of adding content type to attachments
        // This needs to be done outside PRTextStorage from ProtonCore as it can no longer depend on Proton framework
        // Ideally, attachment.string should be used - possibly consider using richTextStorage.replaceCharacters
        richTextStorage.addAttributes(attachment.attributes, range: NSRange(location: range.location, length: 1))
        if let rangeInContainer = attachment.rangeInContainer() {
            edited(range: rangeInContainer)
        }
        scrollRangeToVisible(NSRange(location: range.location, length: 1))
    }

    func edited(range: NSRange) {
        nsTextStorage.beginEditing()
        nsTextStorage.edited([.editedCharacters, .editedAttributes], range: range, changeInLength: 0)
        nsTextStorage.endEditing()
    }

    func transformContents<T: EditorContentEncoding>(in range: NSRange? = nil, using transformer: T) -> [T.EncodedType] {
        return contents(in: range).compactMap(transformer.encode)
    }

    func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        nsTextStorage.replaceCharacters(in: range, with: attrString)
    }

    #if os(iOS)
    func replaceCharacters(in range: NSRange, with string: String) {
        // Delegate to function with attrString so that default attributes are automatically applied
        nsTextStorage.replaceCharacters(in: range, with: NSAttributedString(string: string))
    }
    #else
    override func replaceCharacters(in range: NSRange, with string: String) {
        // Delegate to function with attrString so that default attributes are automatically applied
        nsTextStorage.replaceCharacters(in: range, with: NSAttributedString(string: string))
    }
    #endif

    private func updatePlaceholderVisibility() {
        guard self.attributedText.length == 0 else {
            if placeholderLabel.superview != nil {
                placeholderLabel.removeFromSuperview()
            }
            return
        }
        setupPlaceholder()
    }

    func attributeValue(at location: CGPoint, for attribute: NSAttributedString.Key) -> Any? {
        let characterIndex = nsLayoutManager.characterIndex(for: location, in: nsTextContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < nsTextStorage.length else {
            return nil
        }

        let attributes = nsTextStorage.attributes(at: characterIndex, longestEffectiveRange: nil, in: nsTextStorage.fullRange)
        return attributes[attribute]
    }

    func glyphRange(forCharacterRange range: NSRange) -> NSRange {
        return nsLayoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
    }

    func boundingRect(forGlyphRange range: NSRange) -> CGRect {
        return nsLayoutManager.boundingRect(forGlyphRange: range, in: nsTextContainer)
    }

    func contents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.attributedText.enumerateContents(in: range)
    }

    func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        nsTextStorage.addAttributes(attrs, range: range)
    }

    func removeAttributes(_ attrs: [NSAttributedString.Key], range: NSRange) {
        richTextStorage.removeAttributes(attrs, range: range)
    }

    func enumerateAttribute(_ attrName: NSAttributedString.Key, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        nsTextStorage.enumerateAttribute(attrName, in: enumerationRange, options: opts, using: block)
    }

    #if os(iOS)
    func rangeOfCharacter(at point: CGPoint) -> NSRange? {
        return characterRange(at: point)?.toNSRange(in: self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self)
            didTap(at: position)
        }
    }
    #else
    // TODO: Bridge to macOS
    #endif
    
    func didTap(at location: CGPoint) {
        #if os(iOS)
        let characterRange = rangeOfCharacter(at: location)
        richTextViewDelegate?.richTextView(self, didTapAtLocation: location, characterRange: characterRange)
        #else
        // TODO: Bridge to macOS
        #endif
    }

    // When a user enables `Use keyboard navigation to move focus between controls` it enables the focus system in the app.
    // It means focused item also becomes the first responder. UITextView is focusable by default, but if isEditable is set to false, it cannot be focussed anymore.
    // This leads to an issue where if a user selects text in non-editable text view and right clicks the text view loses the first responder to the focused menu, and therefore no actions are provided, and it is not possible to copy.
    // Returning true will make it focusable regardless if it is editable, and it will not be losing responder because it will stay focused.
    // It is not perfect, as a user can focus this view with Tab and make no actions on it.
    #if os(iOS)
    override var canBecomeFocused: Bool {
        return true
    }
    #else
    // TODO: macOS
    #endif
    
    #if os(iOS)
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard editorView?.canPerformMenuAction(action, withSender: sender) == true else {
            return false
        }

        return super.canPerformAction(action, withSender: sender)
    }
    #else
    // TODO: macOS?
    #endif

    override func copy(_ sender: Any?) {
        if editorView?.responds(to: #selector(copy(_:))) ?? false {
            editorView?.perform(#selector(copy(_:)), with: sender)
        } else {
            super.copy(sender)
        }
    }

    override func paste(_ sender: Any?) {
        if editorView?.responds(to: #selector(paste(_:))) ?? false {
            editorView?.perform(#selector(paste(_:)), with: sender)
        } else {
            super.paste(sender)
        }
    }

    override func cut(_ sender: Any?) {
        if editorView?.responds(to: #selector(cut(_:))) ?? false {
            editorView?.perform(#selector(cut(_:)))
        } else {
            super.cut(sender)
        }
    }

    override func select(_ sender: Any?) {
        if editorView?.responds(to: #selector(select)) ?? false {
            editorView?.perform(#selector(select), with: sender)
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
            editorView?.perform(#selector(toggleUnderline), with: sender)
        } else {
            super.toggleUnderline(sender)
        }
    }

    override func toggleItalics(_ sender: Any?) {
        if editorView?.responds(to: #selector(toggleItalics)) ?? false {
            editorView?.perform(#selector(toggleItalics), with: sender)
        } else {
            super.toggleItalics(sender)
        }
    }

    override func toggleBoldface(_ sender: Any?) {
        if editorView?.responds(to: #selector(toggleBoldface)) ?? false {
            editorView?.perform(#selector(toggleBoldface), with: sender)
        } else {
            super.toggleBoldface(sender)
        }
    }

    #if os(iOS)
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
    #else
    // TODO:
    #endif
}

extension RichTextView: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: PlatformTextContainer?, atEnd layoutFinishedFlag: Bool) {
        richTextViewDelegate?.richTextView(self, didFinishLayout: layoutFinishedFlag)
    }
}

extension RichTextView: TextStorageDelegate {
    func textStorage(_ textStorage: PRTextStorage, didDelete attachment: NSTextAttachment) {
        guard let attachment = attachment as? Attachment else {
            return
        }
        attachment.removeFromSuperview()
    }
    
    func textStorage(_ textStorage: PRTextStorage, will deleteText: NSAttributedString, insertText insertedText: NSAttributedString, in range: NSRange) {
        textProcessor?.textStorage(textStorage, willProcessDeletedText: deleteText, insertedText: insertedText)
    }
    
    func textStorage(_ textStorage: PRTextStorage, edited actions: TextStorageEditAcitons, in editedRange: NSRange, changeInLength delta: Int) {
        updatePlaceholderVisibility()
    }
}

extension RichTextView: LayoutManagerDelegate {
    var listLineFormatting: LineFormatting {
        return richTextViewListDelegate?.listLineFormatting ?? RichTextView.defaultListLineFormatting
    }

    var paragraphStyle: MutableParagraphStyle? {
        return defaultTextFormattingProvider?.paragraphStyle
    }

    func listMarkerForItem(at index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker {
        let font = PlatformFont.preferredFont(forTextStyle: .body)
        let defaultValue = NSAttributedString(string: "*", attributes: [.font: font])
        return richTextViewListDelegate?.richTextView(self, listMarkerForItemAt: index, level: level, previousLevel: previousLevel, attributeValue: attributeValue) ?? .string(defaultValue)
    }
}

#if os(iOS)
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
#else
