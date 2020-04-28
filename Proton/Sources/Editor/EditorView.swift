//
//  EditorView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 5/1/20.
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

/// Describes an object interested in observing the bounds of a view. `Attachment` is `BoundsObserving` and reacts to
/// changes in the bounds of views hosted within the `Attachment`. Any view contained in the `Attachment` that is capable of
/// changing its bounds must define and set `BoundsObserving` to `Attachment`.

/// ### Usage Example ###
/// ```
///  class MyAttachmentView: UIView {
///  weak var boundsObserver: BoundsObserving?
///
///  override var bounds: CGRect {
///      didSet {
///          guard oldValue != bounds else { return }
///          boundsObserver?.didChangeBounds(bounds)
///      }
///     }
///  }
///
///  let myView = MyAttachmentView()
///  let attachment = Attachment(myView, size: .matchContent)
///  myView.boundsObserver = attachment
/// ```
public protocol BoundsObserving: AnyObject {
    /// Lets the observer know that bounds of current object have changed
    /// - Parameter bounds: New bounds
    func didChangeBounds(_ bounds: CGRect)
}

/// Representation of a line of text in `EditorView`. A line is defined as a single fragment starting from the beginning of
/// bounds of `EditorView` to the end. A line may have any number of characters based on the contents in the `EditorView`.
/// - Note:
/// A line does not represent a full sentence in the `EditorView` but instead may start and/or end in the middle of
/// another based on how the content is laid  out in the `EditorView`.
public struct EditorLine {

    /// Text contained in the current line.
    public let text: NSAttributedString

    /// Range of text in the `EditorView` for the current line.
    public let range: NSRange

    /// Determines if the current line starts with given text.
    /// Text comparison is case-sensitive.
    /// - Parameter text: Text to compare
    /// - Returns:
    /// `true` if the current line text starts with the given string.
    public func startsWith(_ text: String) -> Bool {
        return self.text.string.hasPrefix(text)
    }

    /// Determines if the current line ends with given text.
    /// Text comparison is case-sensitive.
    /// - Parameter text: Text to compare
    /// - Returns:
    /// `true` if the current line text ends with the given string.
    public func endsWith(_ text: String) -> Bool {
        self.text.string.hasSuffix(text)
    }

    // EditorLine may only be initialized internally
    init(text: NSAttributedString, range: NSRange) {
        self.text = text
        self.range = range
    }
}

/// A scrollable, multiline text region capable of resizing itself based of the height of the content. Maximum height of `EditorView`
/// may be restricted using an absolute value or by using auto-layout constraints. Instantiation of `EditorView` is simple and straightforward
/// and can be used to host simple formatted text or complex layout containing multiple nested `EditorView` via use of `Attachment`.
open class EditorView: UIView {
    let richTextView: RichTextView

    let context: RichTextViewContext

    var editorContextDelegate: EditorViewDelegate? {
        get { editorViewContext?.delegate }
    }

    let editorViewContext: EditorViewContext?

    var textProcessor: TextProcessor?

    /// An object interested in responding to editing and focus related events in the `EditorView`.
    public weak var delegate: EditorViewDelegate?

    /// List of commands supported by the editor.
    /// - Note:
    /// * To support any command, set value to nil. Default behaviour.
    /// * To prevent any command to be executed, set value to be an empty array.
    public var registeredCommands: [EditorCommand]?

    /// List of actions to be supported by default. These actions are same as what is shown in
    /// `UITextView` Edit menu and when added to the list, will show and execute based on default behaviour.
    /// No code needs to be added for execution of these selectors.
    /// - Note:
    /// To change behavior of a predefined selector like copy or paste, custom menu item(s) must be added with
    /// selector with the intended behavior. In this case, overridden predefined selector must not be added to this list.
    public var supportedMenuSelectors: [Selector]? {
        get { richTextView.supportedMenuSelectors }
        set { richTextView.supportedMenuSelectors = newValue }
    }

    // Making this a convenience init fails the test `testRendersWidthRangeAttachment` as the init of a class subclassed from
    // `EditorView` is returned as type `EditorView` and not the class itself, causing the test to fail.
    /// Initializes the EditorView
    /// - Parameters:
    ///   - frame: Frame to be used for `EditorView`.
    ///   - context: Optional context to be used. `EditorViewContext` is link between `EditorCommandExecutor` and the `EditorView`.
    ///   `EditorCommandExecutor` needs to have same context as the `EditorView` to execute a command on it. Unless you need to have
    ///    restriction around some commands to be restricted in execution on certain specific editors, the default value may be used.
    ///   - growsInfinitely: `true` will optimise for full-height without scroll bars
    public init(frame: CGRect = .zero, context: EditorViewContext = .shared, growsInfinitely: Bool = false) {
        self.context = context.richTextViewContext
        self.editorViewContext = context
        self.richTextView = RichTextView(frame: frame, context: self.context, growsInfinitely: growsInfinitely)

        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    init(frame: CGRect, richTextViewContext: RichTextViewContext, growsInfinitely: Bool = false) {
        self.context = richTextViewContext
        self.richTextView = RichTextView(frame: frame, context: context, growsInfinitely: growsInfinitely)
        self.editorViewContext = nil
        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    /// Input accessory view to be used
    open var editorInputAccessoryView: UIView? {
        get { richTextView.inputAccessoryView }
        set { richTextView.inputAccessoryView = newValue }
    }

    /// Input view to be used
    open var editorInputView: UIView? {
        get { richTextView.inputView }
        set { richTextView.inputView = newValue }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// List of all the registered `TextProcessors` in the `EditorView`. This may be used by nested `EditorView` to inherit all the
    /// text processors from the container `EditorView`.
    /// ### Usage example ###
    /// ```
    /// func execute(on editor: EditorView) {
    ///     let attachment = PanelAttachment(frame: .zero)
    ///     let panel = attachment.view
    ///     panel.editor.registerProcessors(editor.registeredProcessors)
    ///     editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
    /// }
    /// ```
    public var registeredProcessors: [TextProcessing] {
        return textProcessor?.activeProcessors ?? []
    }

    public var selectedTextRange: UITextRange? {
        get { richTextView.selectedTextRange }
        set { richTextView.selectedTextRange = newValue }
    }

    /// Placeholder text for the `EditorView`. The value can contain any attributes which is natively
    /// supported in the `NSAttributedString`.
    public var placeholderText: NSAttributedString? {
        get { richTextView.placeholderText }
        set { richTextView.placeholderText = newValue }
    }

    /// Gets or sets insets for additional scroll area around the content. Default value is UIEdgeInsetsZero.
    public var contentInset: UIEdgeInsets {
        get { richTextView.contentInset }
        set { richTextView.contentInset = newValue }
    }

    /// Gets or sets the insets for the text container's layout area within the editor's content area
    public var textContainerInset: UIEdgeInsets {
        get { richTextView.textContainerInset }
        set { richTextView.textContainerInset = newValue }
    }

    /// The types of data converted to tappable URLs in the editor view.
    public var dataDetectorTypes: UIDataDetectorTypes {
        get { richTextView.dataDetectorTypes }
        set { richTextView.dataDetectorTypes = newValue }
    }

    /// Length of content within the Editor.
    /// - Note:
    /// An attachment is only counted as a single character. Content length does not include
    /// length of content within the Attachment that is hosting another `EditorView`.
    public var contentLength: Int {
        return attributedText.length
    }

    /// Determines if the `EditorView` is editable or not.
    public var isEditable: Bool {
        get { richTextView.isEditable }
        set { richTextView.isEditable = newValue }
    }

    /// Determines if the editor is empty.
    public var isEmpty: Bool {
        return richTextView.attributedText.length == 0
    }

    /// Current line information based the caret position or selected range. If the selected range spans across multiple
    /// lines, only the line information of the line containing the start of the range is returned.
    public var currentLine: EditorLine? {
        return editorLineFrom(range: richTextView.currentLineRange )
    }

    /// First line of content in the Editor. Nil if editor is empty.
    public var firstLine: EditorLine? {
        return editorLineFrom(range: NSRange(location: 1, length: 0) )
    }

    /// Last line of content in the Editor. Nil if editor is empty.
    public var lastLine: EditorLine? {
        return editorLineFrom(range: NSRange(location: contentLength - 1, length: 0) )
    }

    /// Selected text in the editor.
    public var selectedText: NSAttributedString {
        return attributedText.attributedSubstring(from: selectedRange)
    }

    /// Background color for the editor.
    public override var backgroundColor: UIColor? {
        didSet {
            richTextView.backgroundColor = backgroundColor
        }
    }

    /// Default font to be used by the Editor. A font may be overridden on whole or part of content in `EditorView` by an `EditorCommand` or
    /// `TextProcessing` conformances.
    public var font: UIFont = UIFont.preferredFont(forTextStyle: .body) {
        didSet { richTextView.typingAttributes[.font] = font }
    }

    /// Default paragraph style to be used by the Editor. The style may be overridden on whole or part of content in
    /// `EditorView` by an `EditorCommand` or `TextProcessing` conformances.
    public var paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle() {
        didSet { richTextView.typingAttributes[.paragraphStyle] = paragraphStyle }
    }

    /// Default text color to be used by the Editor. The color may be overridden on whole or part of content in
    /// `EditorView` by an `EditorCommand` or `TextProcessing` conformances.
    public var textColor: UIColor {
        get { richTextView.textColor ?? richTextView.defaultTextColor }
        set { richTextView.textColor = newValue }
    }

    /// Maximum height that the `EditorView` can expand to. After reaching the maximum specified height, the editor becomes scrollable.
    /// - Note:
    /// If both auto-layout constraints and `maxHeight` are used, the lower of the two height would be used as maximum allowed height.
    public var maxHeight: CGFloat {
        get { richTextView.maxHeight }
        set { richTextView.maxHeight = newValue }
    }

    /// Text to be set in the `EditorView`
    public var attributedText: NSAttributedString {
        get { richTextView.attributedText }
        set {
            // Focus needs to be set in the Editor without which the
            // encode command fails on macOS
//            richTextView.becomeFirstResponder()
            richTextView.attributedText = newValue
        }
    }

    /// Determines if the selection handles should be shown when `selectedRange` is set programatically. Defaults is `true`.
    public var enableSelectionHandles = true

    /// Gets or sets the selected range in the `EditorView`.
    public var selectedRange: NSRange {
        get { richTextView.selectedRange }
        set {
            if enableSelectionHandles {
                richTextView.select(self)
            }
            richTextView.selectedRange = newValue
        }
    }

    /// Typing attributes to be used. Automatically resets when the selection changes.
    /// To apply an attribute in the current position such that it is applied as text is typed,
    /// the attribute must be added to `typingAttributes` collection.
    public var typingAttributes: [NSAttributedString.Key: Any] {
        get { richTextView.typingAttributes }
        set { richTextView.typingAttributes = newValue }
    }

    /// An object interested in observing the changes in bounds of the `Editor`, typically an `Attachment`.
    public var boundsObserver: BoundsObserving? {
        get { richTextView.boundsObserver }
        set { richTextView.boundsObserver = newValue }
    }

    /// Gets and sets the content offset.
    public var contentOffset: CGPoint {
        get { richTextView.contentOffset }
        set { richTextView.contentOffset = newValue }
    }

    /// The attributes to apply to links.
    public var linkTextAttributes: [NSAttributedString.Key: Any]! {
        get { richTextView.linkTextAttributes }
        set { richTextView.linkTextAttributes = newValue }
    }

    /// Range of end of text in the `EditorView`. The range has always has length of 0.
    public var textEndRange: NSRange {
        return richTextView.textEndRange
    }

    /// Determines if the current Editor is contained in an attachment
    public var isContainedInAnAttachment: Bool {
        return getAttachmentContentView(view: superview) != nil
    }

    /// Name of the content if the Editor is contained within an `Attachment`.
    /// This is done by recursive look-up of views in the `Attachment` content view
    /// i.e. the Editor may be nested in subviews within the contentView of Attachment.
    /// The value is nil if the Editor is not contained within an `Attachment`.
    public var contentName: EditorContent.Name? {
        return getAttachmentContentView(view: superview)?.name
    }

    /// Returns the visible text range.
    public var visibleRange: NSRange {
        return richTextView.visibleRange
    }

    /// Attachment containing the current Editor.
    public var containerAttachment: Attachment? {
        return getAttachmentContentView(view: superview)?.attachment
    }

    /// Nesting level of current Editor within other attachments containing Editors.
    /// 0 indicates that the Editor is not contained in an attachment.
    public var nestingLevel: Int {
        var nestingLevel = 0
        var containerEditor = containerAttachment?.containerEditorView
        while containerEditor != nil {
            nestingLevel += 1
            containerEditor = containerEditor?.containerAttachment?.containerEditorView
        }
        return nestingLevel
    }

    /// Clears the contents in the Editor.
    public func clear() {
        self.attributedText = NSAttributedString()
    }

    /// The autocorrection style for the text object.
    /// The default value for this property is `UITextAutocorrectionType.no`.
    public var autocorrectionType: UITextAutocorrectionType {
        get { richTextView.autocorrectionType }
        set { richTextView.autocorrectionType = newValue }
    }
    
    private func getAttachmentContentView(view: UIView?) -> AttachmentContentView? {
        guard let view = view else { return nil }
        if let attachmentContentView = view.superview as? AttachmentContentView {
            return attachmentContentView
        }
        return getAttachmentContentView(view: view.superview)
    }

    private func setup() {
        richTextView.autocorrectionType = .no

        richTextView.translatesAutoresizingMaskIntoConstraints = false
        richTextView.defaultTextFormattingProvider = self
        richTextView.richTextViewDelegate = self

        addSubview(richTextView)
        NSLayoutConstraint.activate([
            richTextView.topAnchor.constraint(equalTo: topAnchor),
            richTextView.bottomAnchor.constraint(equalTo: bottomAnchor),
            richTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        richTextView.adjustsFontForContentSizeCategory = true
    }

    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - Parameter size: The size for which the view should calculate its best-fitting size.
    /// - Returns:
    /// A new size that fits the receiver’s subviews.
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return richTextView.sizeThatFits(size)
    }

    /// Asks UIKit to make this object the first responder in its window.
    /// - Returns:
    /// `true` if this object is now the first-responder or `false` if it is not.
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return richTextView.becomeFirstResponder()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            // Recalculate fonts!?
        }
    }

    /// Gets the line preceding the given line. Nil if the given line is invalid or is first line
    /// - Parameter line: Reference line
    /// - Returns:
    /// `EditorLine` after the given line. Nil if the Editor is empty or given line is last line in the Editor.
    public func lineAfter(_ line: EditorLine) -> EditorLine? {
        let lineRange = line.range
        let nextLineStartRange = NSRange(location: lineRange.location + lineRange.length + 1, length: 0)
        guard nextLineStartRange.isValidIn(richTextView) else { return nil }
        return editorLineFrom(range: nextLineStartRange)
    }

    /// Gets the line after the given line. Nil if the given line is invalid or is last line
    /// - Parameter line: Reference line
    /// - Returns:
    /// `EditorLine` before the given line. Nil if the Editor is empty or given line is first line in the Editor.
    public func lineBefore(_ line: EditorLine) -> EditorLine? {
        let lineRange = line.range
        let previousLineStartRange = NSRange(location: lineRange.location - 1, length: 0)
        guard previousLineStartRange.isValidIn(richTextView) else { return nil }
        return editorLineFrom(range: previousLineStartRange)
    }

    private func editorLineFrom(range: NSRange?) -> EditorLine? {
        guard let range = range,
            let lineRange = richTextView.lineRange(from: range.location) else { return nil }

        let text = attributedText.attributedSubstring(from: lineRange)
        return EditorLine(text: text, range: lineRange)
    }

    /// Returns the rectangles for line fragments spanned by the range. Based on the span of the range,
    /// multiple rectangles may be returned.
    /// - Parameter range: Range to be queried.
    /// - Returns:
    /// Array of rectangles for the given range.
    public func rects(for range: NSRange) -> [CGRect] {
        guard let textRange = range.toTextRange(textInput: richTextView) else { return [] }
        let rects = richTextView.selectionRects(for: textRange)
        return rects.map { $0.rect }
    }

    /// Returns the caret rectangle for given position in the editor content.
    /// - Parameter position: Location to be queried within the editor content.
    /// - Note:
    ///  If the location is beyond the bounds of content length, the last valid position is used to get caret rectangle. This function
    ///  only returns the rectangle denoting the caret positioning. The actual caret is not moved and no new carets are drawn.
    /// - Returns:
    /// Rectangle for caret based on the line height and given location.
    public func caretRect(for position: Int) -> CGRect {
        let textPosition = richTextView.position(from: richTextView.beginningOfDocument, offset: position) ?? richTextView.endOfDocument
        return richTextView.caretRect(for: textPosition)
    }

    /// Gets the word from text at given location in editor content
    /// - Parameter location: Location to be queried.
    /// - Returns:
    /// Word  at the given location. Nil is there's no content.
    public func word(at location: Int) -> NSAttributedString? {
        return richTextView.wordAt(location)
    }

    /// Inserts an `Attachment` in the `EditorView`.
    /// - Parameters:
    ///   - range: Range where the `Attachment` should be inserted. If the range contains existing content, the content
    ///   will be replaced by the `Attachment`.
    ///   - attachment: Attachment to be inserted.
    public func insertAttachment(in range: NSRange, attachment: Attachment) {
        // TODO: handle undo
        richTextView.insertAttachment(in: range, attachment: attachment)
    }

    /// Sets the focus in the `EditorView`
    public func setFocus() {
        richTextView.becomeFirstResponder()
    }

    /// Makes the `EditorView` lose focus.
    public func resignFocus() {
        richTextView.resignFirstResponder()
    }

    /// Makes the `EditorView` scroll to given range such that it is visible. No-op if the range is already visible.
    /// - Parameter range: Range of content to scroll to.
    public func scrollRangeToVisible(_ range: NSRange) {
        richTextView.scrollRangeToVisible(range)
    }

    /// Makes the `EditorView` scroll to given range such that it is visible. No-op if the range is already visible.
    /// - Parameter range: Range of content to scroll to.
    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        richTextView.scrollRectToVisible(rect, animated: animated)
    }

    /// Gets the contents within the `Editor`.
    /// - Parameter range: Range to be enumerated to get the contents. If no range is specified, entire content range is
    /// enumerated.
    public func contents(in range: NSRange? = nil) -> [EditorContent] {
        let contents = richTextView.contents(in: range)
        return Array(contents)
    }

    /// Transforms `EditorContent` into given type. This function can also be used to encode content into a different type for  e.g. encoding the contents to JSON. Encoding
    /// is  a type of transformation that can also be decoded.
    /// - Parameter range: Range of `Editor` to transform the contents. By default, entire range is used.
    /// - Parameter transformer: Transformer capable of transforming `EditorContent` to given type
    /// - Returns:
    /// Array of transformed contents based on given transformer.
    public func transformContents<T: EditorContentEncoding>(in range: NSRange? = nil, using transformer: T) -> [T.EncodedType] {
        return richTextView.transformContents(in: range, using: transformer)
    }

    /// Replaces the given range of content with the attributedString provided.
    /// - Parameters:
    ///   - range: Range to replace.
    ///   - attributedString: Text to replace the range of content with.
    public func replaceCharacters(in range: NSRange, with attributedString: NSAttributedString) {
        richTextView.replaceCharacters(in: range, with: attributedString)
    }

    /// Replaces the characters in the given range with the string provided.
    /// - Attention:
    /// The string provided will use the default `font` and `paragraphStyle` set in the `EditorView`. It will not retain any other attributes already applied on
    /// the range of text being replaced by the `string`. If you would like add any other attributes, it is best to use `replaceCharacters` with the parameter value of
    /// type `NSAttributedString` that may have additional attributes defined, as well as customised `font` and `paragraphStyle` applied.
    /// - Parameter range: Range of text to replace. For an empty `EditorView`, you may pass `NSRange.zero` to insert text at the beginning.
    /// - Parameter string: String to replace the range of text with. The string will use default `font` and `paragraphStyle` defined in the `EditorView`.
    public func replaceCharacters(in range: NSRange, with string: String) {
        let attributedString = NSAttributedString(string: string, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: textColor
        ])
        richTextView.replaceCharacters(in: range, with: attributedString)
    }

    /// Appends the given attributed text to the end of content in `EditorView`.
    /// - Parameter attributedString: Text to append.
    public func appendCharacters(_ attributedString: NSAttributedString) {
        replaceCharacters(in: textEndRange, with: attributedString)
    }

    /// Appends the given attributed text to the end of content in `EditorView`.
    /// - Parameter string: Text to append.
    public func appendCharacters(_ string: String) {
        richTextView.replaceCharacters(in: textEndRange, with: string)
    }

    /// Registers the given text processor with the editor.
    /// - Parameter processor: Text processor to register
    public func registerProcessor(_ processor: TextProcessing) {
        textProcessor?.register(processor)
    }

    /// Unregisters the given text processor from the editor.
    /// - Parameter processor: Text processor to unregister
    public func unregisterProcessor(_ processor: TextProcessing) {
        textProcessor?.unregister(processor)
    }

    /// Registers the given text processors with the editor.
    /// - Parameter processors: Text processors to register
    public func registerProcessors(_ processors: [TextProcessing]) {
        textProcessor?.register(processors)
    }

    /// Unregisters the given text processors from the editor.
    /// - Parameter processors: Text processors to unregister
    public func unregisterProcessors(_ processors: [TextProcessing]) {
        textProcessor?.unregister(processors)
    }

    /// Registers the given commands with the Editor. Only registered commands can be executed if any is added to the Editor.
    /// - Parameter commands: Commands to register
    public func registerCommands(_ commands: [EditorCommand]) {
        if registeredCommands == nil {
            registeredCommands = []
        }

        // cleanup the array being passed in to include only the last command for registration
        // if more than one commands have same name
        var commandsToRegister = [EditorCommand]()
        for c in commands {
            if commandsToRegister.contains (where: { $0.name == c.name }) {
                commandsToRegister.removeAll { $0.name == c.name }
            }
            commandsToRegister.append(c)
        }

        registeredCommands?.removeAll { c in
            commandsToRegister.contains { $0.name == c.name }
        }

        registeredCommands?.append(contentsOf: commandsToRegister)
    }

    /// Unregisters the given commands from the Editor. When all commands are unregistered, any command can be executed on the editor.
    /// - Parameter commands: Commands to unregister
    public func unregisterCommands(_ commands: [EditorCommand]) {
        registeredCommands?.removeAll { c in
            commands.contains { $0.name == c.name }
        }
        if registeredCommands?.count == 0 {
            registeredCommands = nil
        }
    }

    /// Registers the given command with the Editor. Only registered commands can be executed if any is added to the Editor.
    /// - Parameter commands: Command to register
    public func registerCommand(_ command: EditorCommand) {
        registerCommands([command])
    }

    /// Unregisters the given command from the Editor. When all commands are unregistered, any command can be executed on the editor.
    /// - Parameter commands: Command to unregister
    public func unregisterCommand(_ command: EditorCommand) {
        unregisterCommands([command])
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return richTextView.canPerformAction(action, withSender: sender)
    }
}

extension EditorView {

    /// Adds given attributes to the range provided. If the range already contains a value for an attribute being provided,
    /// existing value will be overwritten by the new value provided in the attributes.
    /// - Parameters:
    ///   - attributes: Attributes to be added.
    ///   - range: Range on which attributes should be applied to.
    public func addAttributes(_ attributes: [NSAttributedString.Key: Any], at range: NSRange) {
        self.richTextView.addAttributes(attributes, range: range)
        self.richTextView.enumerateAttribute(.attachment, in: range, options: .longestEffectiveRangeNotRequired) { value, rangeInContainer, _ in
            if let attachment = value as? Attachment {
                attachment.addedAttributesOnContainingRange(rangeInContainer: rangeInContainer, attributes: attributes)
            }
        }
    }

    /// Removes the given attributes from the range provided. If the attribute does not exist in the range, it will be a no-op.
    /// - Parameters:
    ///   - attributes: Attributes to remove.
    ///   - range: Range to remove the attributes from.
    public func removeAttributes(_ attributes: [NSAttributedString.Key], at range: NSRange) {
        self.richTextView.removeAttributes(attributes, range: range)
        self.richTextView.enumerateAttribute(.attachment, in: range, options: .longestEffectiveRangeNotRequired) { value, rangeInContainer, _ in
            if let attachment = value as? Attachment {
                attachment.removedAttributesFromContainingRange(rangeInContainer: rangeInContainer, attributes: attributes)
            }
        }
    }

    /// Adds given attribute to the range provided. If the attribute already exists in the range, it will be overwritten with the new value provided here.
    /// - Parameters:
    ///   - name: Key of the attribute to add.
    ///   - value: Value of the attribute.
    ///   - range: Range to which attribute should be added.
    public func addAttribute(_ name: NSAttributedString.Key, value: Any, at range: NSRange) {
        self.addAttributes([name: value], at: range)
    }

    /// Removes the attribute from given range. If the attribute does not exist in the range, it is a no-op.
    /// - Parameters:
    ///   - name: Key of attribute to be removed.
    ///   - range: Range from which attribute should be removed.
    public func removeAttribute(_ name: NSAttributedString.Key, at range: NSRange) {
        self.removeAttributes([name], at: range)
    }
}

extension EditorView: DefaultTextFormattingProviding { }

extension EditorView: RichTextViewDelegate {
    func richTextView(_ richTextView: RichTextView, didChangeSelection range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        delegate?.editor(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
        editorContextDelegate?.editor(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveKey key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange, handled: inout Bool) {
        guard modifierFlags.isEmpty else {
            textProcessor?.activeProcessors.forEach { processor in
                processor.handleKeyWithModifiers(editor: self, key: key, modifierFlags: modifierFlags, range: range)
            }
            return
        }
        delegate?.editor(self, didReceiveKey: key, at: range, handled: &handled)
        editorContextDelegate?.editor(self, didReceiveKey: key, at: range, handled: &handled)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange) {
        delegate?.editor(self, didReceiveFocusAt: range)
        editorContextDelegate?.editor(self, didReceiveFocusAt: range)
    }

    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange) {
        delegate?.editor(self, didLoseFocusFrom: range)
        editorContextDelegate?.editor(self, didLoseFocusFrom: range)
    }

    func richTextView(_ richTextView: RichTextView, didChangeTextAtRange range: NSRange) {
        delegate?.editor(self, didChangeTextAt: range)
        editorContextDelegate?.editor(self, didChangeTextAt: range)
    }

    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool) {
        guard finished else { return }
        relayoutAttachments()
    }

    func richTextView(_ richTextView: RichTextView, selectedRangeChangedFrom oldRange: NSRange?, to newRange: NSRange?) {
        textProcessor?.activeProcessors.forEach{ $0.selectedRangeChanged(editor: self, oldRange: oldRange, newRange: newRange) }
    }

    func richTextView(_ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?) { }
}

extension EditorView {
    func invalidateLayout(for range: NSRange) {
        richTextView.invalidateLayout(for: range)
    }

    func relayoutAttachments() {
        richTextView.enumerateAttribute(.attachment, in: NSRange(location: 0, length: richTextView.contentLength), options: .longestEffectiveRangeNotRequired) { (attach, range, _) in
            guard let attachment = attach as? Attachment else { return }

            // Remove attachment from container if it is already added to another Editor
            // for e.g. when moving text with attachment into another attachment
            if attachment.containerEditorView != self {
                attachment.removeFromContainer()
            }

            var frame = richTextView.boundingRect(forGlyphRange: range)
            frame.origin.y += self.textContainerInset.top

            var size = attachment.frame.size
            if size == .zero,
                let contentSize = attachment.contentView?.systemLayoutSizeFitting(bounds.size) {
                size = contentSize
            }

            frame = CGRect(origin: frame.origin, size: size)

            if attachment.isRendered == false {
                attachment.render(in: self)
                if let focusable = attachment.contentView as? Focusable {
                    focusable.setFocus()
                }
            }
            attachment.frame = frame
        }
    }
}

public extension EditorView {
    /// Creates a `RendererView` from current `EditorView`
    /// - Returns:
    /// `RendererView` for the Editor
    func convertToRenderer() -> RendererView {
        return RendererView(editor: self)
    }

    /// Determines if the given command can be executed on the current editor. The command is allowed to be executed if
    /// `requiresSupportedCommandsRegistration` is false or if the command has been registered with the editor.
    /// - Parameter command: Command to validate
    /// - Returns:
    /// `true` if the command is registered with the Editor.
    func isCommandRegistered(_ name: CommandName) -> Bool {
        return registeredCommands?.contains { $0.name == name } ?? true
    }
}
