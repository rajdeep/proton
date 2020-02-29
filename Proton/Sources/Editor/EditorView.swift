//
//  EditorView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 5/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
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
public protocol BoundsObserving: class {

    /// Lets the observer know that bounds of current object have changed
    /// - Parameter bounds: New bounds
    func didChangeBounds(_ bounds: CGRect)
}

/// Representation of a line of text in `EditorView`. A line is defined as a single fragment starting from the beginning of
/// bounds of `EditorView` to the end. A line may have any number of characters based on the contents in the `EditorView`.
/// - Note: A line does not represent a full sentence in the `EditorView` but instead may start and/or end in the middle of
/// another based on how the content is laid  out in the `EditorView`.
public struct EditorLine {

    /// Text contained in the current line.
    public let text: NSAttributedString

    /// Range of text in the `EditorView` for the current line.
    public let range: NSRange

    /// Determines if the current line starts with given text.
    /// Text comparison is case-sensitive.
    /// - Parameter text: Text to compare
    public func startsWith(_ text: String) -> Bool {
        return self.text.string.hasPrefix(text)
    }

    /// Determines if the current line ends with given text.
    /// Text comparison is case-sensitive.
    /// - Parameter text: Text to compare
    public func endsWith(_ text: String) -> Bool {
        self.text.string.hasSuffix(text)
    }
}

/// A scrollable, multiline text region capable of resizing itself based of the height of the content. Maximum height of `EditorView`
/// may be restricted using an absolute value or by using auto-layout constraints. Instantiation of `EditorView` is simple and straightforward
/// and can be used to host simple formatted text or complex layout containing multiple nested `EditorView` via use of `Attachment`.
open class EditorView: UIView {
    let richTextView: RichTextView

    let context: RichTextViewContext

    /// An object interested in responding to editing and focus related events in the `EditorView`.
    public weak var delegate: EditorViewDelegate?
    var textProcessor: TextProcessor?

    /// List of commands supported by the editor.
    /// -Note:
    /// * To support any command, set `requiresSupportedCommandsRegistration` to `false`
    /// * To prevent any command to be executed, set `requiresSupportedCommandsRegistration` to true and keep this list empty.
    public private(set) var supportedCommands = [EditorCommand]() {
        didSet {
            requiresSupportedCommandsRegistration = supportedCommands.count > 0
        }
    }

    // Making this a convenience init fails the test `testRendersWidthRangeAttachment` as the init of a class subclassed from
    // `EditorView` is returned as type `EditorView` and not the class itself, causing the test to fail.
    /// Initializes the EditorView
    /// - Parameters:
    ///   - frame: Frame to be used for `EditorView`.
    ///   - context: Optional context to be used. `EditorViewContext` is link between `EditorCommandExecutor` and the `EditorView`.
    ///   `EditorCommandExecutor` needs to have same context as the `EditorView` to execute a command on it. Unless you need to have
    ///    restriction around some commands to be restricted in execution on certain specific editors, the default value may be used.
    public init(frame: CGRect = .zero, context: EditorViewContext = .shared) {
        self.context = context.richTextViewContext
        self.richTextView = RichTextView(frame: frame, context: self.context)

        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    init(frame: CGRect, richTextViewContext: RichTextViewContext) {
        self.context = richTextViewContext
        self.richTextView = RichTextView(frame: frame, context: context)

        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    /// Input accessory view to be used
    open var editorInputAccessoryView: UIView? {
        get { return richTextView.inputAccessoryView }
        set { richTextView.inputAccessoryView = newValue }
    }

    /// Input view to be used
    open var editorInputView: UIView? {
        get { return richTextView.inputView }
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

    /// Determines if the editor requires explicit registration of commands. This works in conjunction with `supportedCommands` which
    /// may be registered by using `registerCommand(:)` or `registerCommands(:)`.
    /// - Important:
    /// This applies only when executing commands via `EditorCommandExecutor`. When executing a command directly on the `EditorView`, this is
    /// governed by `canExecute(:)` of the `EditorCommand`. By default, it uses same logic as `EditorCommandExecutor` but if the command has
    /// custom implementation of `canExecute(:)`, its the responsibility of developer of command to check if the command should be allowed to be
    /// executed on the given editor.
    ///
    /// - Note:
    /// * When `requiresSupportedCommandsRegistration` == true and no commands are registered, no command can be executed on the Editor.
    /// * When `requiresSupportedCommandsRegistration` == false, any command can be executed without being registered.
    /// * When `requiresSupportedCommandsRegistration` == true and some commands are registered, only registered command can be executed on the Editor.
    /// * When one or more commands are registered with Editor, `requiresSupportedCommandsRegistration` is automatically set to `true`.
    /// * When all registered commands are unregistered from Editor, `requiresSupportedCommandsRegistration` is automatically set to `false`.
    public var requiresSupportedCommandsRegistration: Bool = false

    /// Placeholder text for the `EditorView`. The value can contain any attributes which is natively
    /// supported in the `NSAttributedString`.
    public var placeholderText: NSAttributedString? {
        get { richTextView.placeholderText }
        set { richTextView.placeholderText = newValue}
    }

    /// Default value is UIEdgeInsetsZero. Add insets for additional scroll area around the content.
    public var contentInset: UIEdgeInsets {
        get { richTextView.contentInset }
        set { richTextView.contentInset = newValue }
    }

    /// Inset the text container's layout area within the editor's content area
    public var textContainerInset: UIEdgeInsets {
        get { richTextView.textContainerInset }
        set { richTextView.textContainerInset = newValue }
    }

    /// Length of content within the Editor.
    /// - Note: An attachment is only counted as a single character. Content length does not include
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
    public var currentLine: EditorLine {
        let lineRange = richTextView.currentLineRange
        let text = attributedText.attributedSubstring(from: lineRange)
        return EditorLine(text: text, range: lineRange)
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
        get { return richTextView.textColor ?? UIColor.label }
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
        get { return richTextView.attributedText }
        set {
            // Focus needs to be set in the Editor without which the
            // encode command fails on macOS
            richTextView.becomeFirstResponder()
            richTextView.attributedText = newValue
        }
    }

    /// Determines if the selection handles should be shown when `selectedRange` is set. Defaults to `true`.
    public var enableSelectionHandles = true

    /// Gets or sets the selected range in the `EditorView`.
    public var selectedRange: NSRange {
        get { return richTextView.selectedRange }
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
        get { return richTextView.typingAttributes }
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

    /// Range of end of text in the `EditorView`
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
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
        richTextView.adjustsFontForContentSizeCategory = true
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return richTextView.becomeFirstResponder()
    }

    /// Returns the rectangles for line fragments spanned by the range. Based on the span of the range,
    /// multiple rectangles may be returned.
    /// - Parameter range: Range to be queried.
    public func rects(for range: NSRange) -> [CGRect] {
        guard let textRange = range.toTextRange(textInput: richTextView) else { return [] }
        let rects = richTextView.selectionRects(for: textRange)
        return rects.map { $0.rect }
    }

    /// Returns the caret rectangle for given position in the editor content.
    /// - Parameter position: Location to be queried within the editor content.
    /// - Note:
    ///  If the location is beyond the bounds of content length, the last valid position is used to get caret rectangle.
    public func caretRect(for position: Int) -> CGRect {
        let textPosition = richTextView.position(from: richTextView.beginningOfDocument, offset: position) ?? richTextView.endOfDocument
        return richTextView.caretRect(for: textPosition)
    }

    /// Gets the word from text at given location in editor content
    /// - Parameter location: Location to be queried.
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
        let contents =  richTextView.contents(in: range)
        return Array(contents)
    }

    /// Transforms `EditorContent` into given type. This function can also be used to encode content into a different type for  e.g. encoding the contents to JSON. Encoding
    /// is  a type of transformation that can also be decoded.
    /// - Parameter range: Range of `Editor` to transform the contents. By default, entire range is used.
    /// - Parameter transformer: Transformer capable of transforming `EditorContent` to given type
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
        let attributes: RichTextAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: font as Any,
            NSAttributedString.Key.foregroundColor: textColor as Any
        ]

        let attributedString = NSAttributedString(string: string, attributes: attributes)
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
        supportedCommands.append(contentsOf: commands)
    }

    /// Unregisters the given commands from the Editor. When all commands are unregistered, any command can be executed with the editor.
    /// - Parameter commands: Commands to unregister
    public func unregisterCommands(_ commands: [EditorCommand]) {
        supportedCommands.removeAll { c in
            commands.contains { $0 === c }
        }
    }

    /// Registers the given command with the Editor. Only registered commands can be executed if any is added to the Editor.
    /// - Parameter commands: Command to register
    public func registerCommand(_ command: EditorCommand) {
        registerCommands([command])
    }

    /// Unregisters the given command from the Editor. When all commands are unregistered, any command can be executed with the editor.
    /// - Parameter commands: Command to unregister
    public func unregisterCommand(_ command: EditorCommand) {
        unregisterCommands([command])
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
    }

    func richTextView(_ richTextView: RichTextView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) {
        delegate?.editor(self, didReceiveKey: key, at: range, handled: &handled)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange) {
        delegate?.editor(self, didReceiveFocusAt: range)
    }

    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange) {
        delegate?.editor(self, didLoseFocusFrom: range)
    }

    func richTextView(_ richTextView: RichTextView, didChangeTextAtRange range: NSRange) {
        delegate?.editor(self, didChangeTextAt: range)
    }

    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool) {
        guard finished else { return }
        relayoutAttachments()
    }

    func richTextView(_ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?) { }
}

extension EditorView {
    func invalidateLayout(for range: NSRange) {
        richTextView.invalidateLayout(for: range)
    }

    func relayoutAttachments() {
        richTextView.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: richTextView.contentLength), options: .longestEffectiveRangeNotRequired) { (attach, range, _) in
            guard let attachment = attach as? Attachment
                else { return }

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
    func convertToRenderer() -> RendererView {
        return RendererView(editor: self)
    }

    /// Determines if the given command can be executed on the current editor. The command is allowed to be executed if
    /// `requiresSupportedCommandsRegistration` is false or if the command has been registered with the editor.
    /// - Parameter command: Command to validate
    func isCommandSupported(_ command: EditorCommand) -> Bool {
        return requiresSupportedCommandsRegistration == false || supportedCommands.contains { $0 === command }
    }
}
