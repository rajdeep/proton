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
import ProtonCore

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
    func didChangeBounds(_ bounds: CGRect, oldBounds: CGRect)
}

/// Describes opening and closing separators for `EditorView`'`getFullAttributedText(:)` function.
public struct AttachmentContentIdentifier {
    
    public let openingID: NSAttributedString
    public let closingID: NSAttributedString

    /// Constructs separators for using in `getFullAttributedText(:)`
    /// - Parameters:
    ///   - openingID: Used to identify start of attachment content
    ///   - closingID: Used to identify end of attachment content
    init(openingID: NSAttributedString, closingID: NSAttributedString) {
        self.openingID = openingID
        self.closingID = closingID
    }
}

/// Defines the height for the Editor
public enum EditorHeight {
    /// Default controlled via autolayout.
    case `default`
    /// Maximum height editor is allowed to grow to before it starts scrolling
    case max(_ height: CGFloat)
    /// Boundless height.
    /// - Important: Editor must not have auto-layout constraints on height failing which the editor will stop growing per height
    ///  constraints and will not scroll beyond that point i.e. scrollbars would not be visible.
    case infinite
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
    private var defaultTextColor: UIColor?
    var textProcessor: TextProcessor?
    let richTextView: RichTextView
    let context: RichTextViewContext
    var needsAsyncTextResolution = false

    private let attachmentRenderingScheduler = AsyncTaskScheduler()
    // Used for tracking rendered viewport in async behaviour specifically to ensure calling
    // `didCompleteRenderingViewport` only once for each viewport value.
    private var renderedViewport: CGRect? {
        didSet {
            guard let renderedViewport,
                  renderedViewport != oldValue else { return }

            asyncAttachmentRenderingDelegate?.didCompleteRenderingViewport(renderedViewport, in: self)
        }
    }


    // Holds `attributedText` until Editor move to a window
    // Setting attributed text without Editor being fully ready
    // causes issues with cached bounds that shows up when rotating the device.
    private var pendingAttributedText: NSAttributedString?

    var editorContextDelegate: EditorViewDelegate? {
        get { editorViewContext.delegate }
    }

    public var scrollView: UIScrollView {
        richTextView as UIScrollView
    }

    /// Context for the current Editor
    public let editorViewContext: EditorViewContext

    /// Returns if `attributedText` change is pending. `AttributedText` may not have been applied if the `EditorView` is not already on
    /// `window` and `forceApplyAttributedText` is not set to `true`.
    public var isAttributedTextPending: Bool {
        pendingAttributedText != nil
    }

    /// Enables asynchronous rendering of attachments.
    /// - Note:
    /// Since attachments must me rendered on main thread, the rendering only continues when there is no user interaction. By default, rendering starts
    /// immediately after the content is set in the `EditorView`. However, since attachments must render on main thread only, as soon as there is a user
    /// interaction event, like scrolling, is received, the rendering is paused until scrolling stops and then, resumes again.
    /// - Important:
    /// This feature allows for almost instantaneous load of the editor content. However, this is only recommended when there are lots of attachments that
    /// may be causing overall load time to be in unacceptable region. Since attachments are rendered one at a time, for simple content, the overall load time
    /// mat be more than when synchronous mode, ie default, is used. The perceived performance/TTI will almost always be better with asynchronous rendering.
    public weak var asyncAttachmentRenderingDelegate: AsyncAttachmentRenderingDelegate?

    /// Returns `UITextInput` of current instance
    public var textInput: UITextInput {
        richTextView
    }

    public var textInteractions: [UITextInteraction] {
        richTextView.interactions.compactMap({ $0 as? UITextInteraction })
    }

    public var textViewGestures: [UIGestureRecognizer] {
        richTextView.gestureRecognizers ?? []
    }

    public var textDragInteractionEnabled: Bool {
        get { richTextView.textDragInteraction?.isEnabled ?? false }
        set { richTextView.textDragInteraction?.isEnabled = newValue }
    }

    /// Line number provider to be used to show custom line numbers in gutter.
    /// - Note: Only applicable when `isLineNumbersEnabled` is set to `true`
    public var lineNumberProvider: LineNumberProvider? {
        get { richTextView.lineNumberProvider }
        set { richTextView.lineNumberProvider = newValue }
    }

    public var isLineNumbersEnabled: Bool {
        get { richTextView.isLineNumbersEnabled }
        set { richTextView.isLineNumbersEnabled = newValue }
    }
    
    public var lineNumberFormatting: LineNumberFormatting {
        get { richTextView.lineNumberFormatting }
        set { richTextView.lineNumberFormatting = newValue }
    }

    public override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else { return }
            for (attachment, _) in attributedText.attachmentRanges where attachment.isContainerDependentSizing {
                if attachment.cachedContainerSize != bounds.size {
                    attachment.cachedBounds = nil
                }
            }
            AggregateEditorViewDelegate.editor(self, didChangeSize: bounds.size, previousSize: oldValue.size)
        }
    }

    /// An object interested in responding to editing and focus related events in the `EditorView`.
    open weak var delegate: EditorViewDelegate?

    /// List formatting provider to be used for rendering lists in the Editor.
    public weak var listFormattingProvider: EditorListFormattingProvider?

    /// List of commands supported by the editor.
    /// - Note:
    /// * To support any command, set value to nil. Default behaviour.
    /// * To prevent any command to be executed, set value to be an empty array.
    public var registeredCommands: [EditorCommand]?

    /// Async Text Resolvers supported by the Editor.
    public var asyncTextResolvers: [AsyncTextResolving] = []

    /// Low-tech lock mechanism to know when `attributedText` is being set
    private var isSettingAttributedText = false

    // Making this a convenience init fails the test `testRendersWidthRangeAttachment` as the init of a class subclassed from
    // `EditorView` is returned as type `EditorView` and not the class itself, causing the test to fail.
    /// Initializes the EditorView
    /// - Parameters:
    ///   - frame: Frame to be used for `EditorView`.
    ///   - context: Optional context to be used. `EditorViewContext` is link between `EditorCommandExecutor` and the `EditorView`.
    ///   `EditorCommandExecutor` needs to have same context as the `EditorView` to execute a command on it. Unless you need to have
    ///    restriction around some commands to be restricted in execution on certain specific editors, the default value may be used.
    public init(frame: CGRect = .zero, context: EditorViewContext = .shared, allowAutogrowing: Bool = true) {
        self.context = context.richTextViewContext
        self.editorViewContext = context
        self.richTextView = RichTextView(frame: frame, context: self.context, allowAutogrowing: allowAutogrowing)

        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    init(frame: CGRect, richTextViewContext: RichTextViewContext, allowAutogrowing: Bool = true) {
        self.context = richTextViewContext
        self.richTextView = RichTextView(frame: frame, context: context, allowAutogrowing: allowAutogrowing)
        self.editorViewContext = .null
        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    /// Input accessory view to be used
    open var editorInputAccessoryView: UIView? {
        get {
#if !os(visionOS)
            return richTextView.inputAccessoryView
#else
            return nil
#endif
        } set {
#if os(visionOS)
            return
#else
            richTextView.inputAccessoryView = newValue
#endif
        }
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

    public var scrollViewDelegate: UIScrollViewDelegate? {
        get { richTextView.richTextScrollViewDelegate }
        set { richTextView.richTextScrollViewDelegate  = newValue }
    }

    public var panGestureRecognizer: UIGestureRecognizer {
        get { scrollView.panGestureRecognizer }
    }

    public var pinchGestureRecognizer: UIPinchGestureRecognizer? {
        get { scrollView.pinchGestureRecognizer }
    }

    public var directionalPressGestureRecognizer: UIGestureRecognizer? {
        get { scrollView.directionalPressGestureRecognizer }
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

    public var verticalScrollIndicatorInsets: UIEdgeInsets {
        get { richTextView.verticalScrollIndicatorInsets }
        set { richTextView.verticalScrollIndicatorInsets = newValue }
    }
    
#if !os(visionOS)
    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode {
        get { richTextView.keyboardDismissMode }
        set { richTextView.keyboardDismissMode = newValue }
    }
#endif

    
    public var isScrollEnabled: Bool {
        get { richTextView.isScrollEnabled }
        set { richTextView.isScrollEnabled = newValue }
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
        guard pendingAttributedText == nil else { return attributedText.length }
        return richTextView.contentLength
    }

    /// Determines if the `EditorView` is editable or not.
    /// - Note:
    /// Setting `isEditable` to `false` before setting the `attributedText` will make `EditorView` skip certain layout paths
    /// and calculations for attachments containing `UIView`s, This is done primarily to improve the rendering performance of the `EditorView`
    /// in case of text with large number of attachments. 
    public var isEditable: Bool {
        get { richTextView.isEditable }
        set {
            richTextView.isEditable = newValue
            AggregateEditorViewDelegate.editor(self, didChangeEditable: newValue)
        }
    }

    /// Determines if the editor is empty.
    public var isEmpty: Bool {
        return richTextView.attributedText.length == 0
    }

    /// Current line information based the caret position or selected range. If the selected range spans across multiple
    /// lines, only the line information of the line containing the start of the range is returned.
    /// - Note:
    /// This is based on the layout of text in the `EditorView` and not on the actual lines based on `\n`. The range may
    /// contain multiple lines or part of different lines separated by `\n`.
    /// To get lines based on new line characters, please use `contentLinesInRange(range)`, `previousContentLine(location)`
    /// and `nextContentLine(location)`.
    public var currentLayoutLine: EditorLine? {
        return editorLayoutLineFrom(range: richTextView.currentLineRange )
    }

    /// First line of content based on layout in the Editor. Nil if editor is empty.
    /// - Note:
    /// This is based on the layout of text in the `EditorView` and not on the actual lines based on `\n`. The range may
    /// contain multiple lines or part of different lines separated by `\n`.
    /// To get lines based on new line characters, please use `contentLinesInRange(range)`, `previousContentLine(location)`
    /// and `nextContentLine(location)`.
    public var firstLayoutLine: EditorLine? {
        return editorLayoutLineFrom(range: NSRange(location: 1, length: 0) )
    }

    /// Last line of content based on layout in the Editor. Nil if editor is empty.
    /// - Note:
    /// This is based on the layout of text in the `EditorView` and not on the actual lines based on `\n`. The range may
    /// contain multiple lines or part of different lines separated by `\n`.
    /// To get lines based on new line characters, please use `contentLinesInRange(range)`, `previousContentLine(location)`
    /// and `nextContentLine(location)`.
    public var lastLayoutLine: EditorLine? {
        return editorLayoutLineFrom(range: NSRange(location: contentLength - 1, length: 0) )
    }

    /// Selected text in the editor.
    public var selectedText: NSAttributedString {
        return attributedText.attributedSubstring(from: selectedRange)
    }

    /// Background color for the editor.
    public override var backgroundColor: UIColor? {
        didSet {
            richTextView.backgroundColor = backgroundColor
            if backgroundColor != oldValue {
                updateBackgroundInheritingViews(color: backgroundColor, oldColor: backgroundColor)
            }
            delegate?.editor(self, didChangeBackgroundColor: backgroundColor, oldColor: oldValue)
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
        get { defaultTextColor ?? richTextView.defaultTextColor }
        set {
            defaultTextColor = newValue
            richTextView.textColor = newValue
        }
    }

    /// Maximum height that the `EditorView` can expand to. After reaching the maximum specified height, the editor becomes scrollable.
    /// - Note:
    /// If both auto-layout constraints and `maxHeight` are used, the lower of the two height would be used as maximum allowed height.
    public var maxHeight: EditorHeight {
        get {
            let height = richTextView.maxHeight
            switch height {
            case 0:
                return .default
            case .greatestFiniteMagnitude:
                return .infinite
            default:
                return .max(height)
            }

        }
        set {
            switch newValue {
            case let .max(height):
                richTextView.maxHeight = height
            case .default:
                richTextView.maxHeight = 0
            case .infinite:
                richTextView.maxHeight = .greatestFiniteMagnitude
            }
        }
    }

    /// Forces setting attributed text in `EditorView` even if it is not
    /// yet in view hierarchy.
    /// - Note: This may result in misplaced `Attachment`s and is recommended to be set to `true` only in unit tests.
    public var forceApplyAttributedText = false

    /// Text to be set in the `EditorView`
    /// - Important: `attributedText` is not set for rendering in `EditorView` if the `EditorView` is not already in a `Window`. Value of `true`
    /// for `isAttributedTextPending` confirms that the text has not yet been rendered even though it is set in the `EditorView`.
    /// Notification of text being set can be observed by subscribing to `didSetAttributedText` in `EditorViewDelegate`.
    /// Alternatively, `forceApplyAttributedText` may be set to `true` to always apply `attributedText` irrespective of `EditorView` being
    /// in a `Window` or not.
    public var attributedText: NSAttributedString {
        get {
            pendingAttributedText ?? richTextView.attributedText
        }
        set {
            if forceApplyAttributedText == false && window == nil {
                pendingAttributedText = newValue
                return
            }
            attachmentRenderingScheduler.cancel()
            renderedViewport = nil
            // Clear text before setting new value to avoid issues with formatting/layout when
            // editor is hosted in a scrollable container and content is set multiple times.
            richTextView.attributedText = NSAttributedString()

            let isDeferred = pendingAttributedText != nil
            pendingAttributedText = nil

            AggregateEditorViewDelegate.editor(self, willSetAttributedText: newValue, isDeferred: isDeferred)
            isSettingAttributedText = true
            richTextView.attributedText = newValue
            isSettingAttributedText = false
            AggregateEditorViewDelegate.editor(self, didSetAttributedText: newValue, isDeferred: isDeferred)
        }
    }

    public var nestedEditors: [EditorView] {
        richTextView.nestedTextViews.compactMap { $0.editorView }
    }

    public var text: String {
        richTextView.text
    }

    public var selectedRange: NSRange {
        get { richTextView.ensuringValidSelectedRange() }
        set { richTextView.selectedRange = newValue }
    }

    public var lineFragmentPadding: CGFloat {
        richTextView.textContainer.lineFragmentPadding
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

    /// The size of the content view.
    public var contentSize: CGSize {
        get { richTextView.contentSize }
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

    /// Returns the visible bounds of the `EditorView` within a scrollable container.
    /// - Note:
    /// If `EditorView` has defined a `ViewportProvider`, the `viewport` is calculated per the provider.
    /// A `ViewportProvider` may be needed in cases where `EditorView` is hosted inside another `UIScrollView` and the
    /// viewport needs to be calculated based on the viewport of container `UIScrollView`.
    open var viewport: CGRect {
        return asyncAttachmentRenderingDelegate?.prioritizedViewport ?? richTextView.viewport
    }

    /// Returns the visible text range. In case of non-scrollable `EditorView`, entire range is `visibleRange`.
    /// The range may be `nil` if it is queried before layout has begun
    /// - Note:
    /// If `EditorView` has defined a `ViewportProvider`, the `visibleRange` is calculated per the `viewport` from provider.
    /// A `ViewportProvider` may be needed in cases where `EditorView` is hosted inside another `UIScrollView` and the
    /// viewport needs to be calculated based on the viewport of container `UIScrollView`.
    public var visibleRange: NSRange? {
        rangeForRect(viewport)
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

    /// Returns if the `EditorView` is a root editor i.e. not contained in any `Attachment`
    public var isRootEditor: Bool {
        parentEditor == nil
    }

    /// Returns the root editor of the current Editor. Returns `self` where the current editor is not contained within an `Attachment`.
    /// - Note:This is different from `parentEditor` which is immediate parent of the current editor
    public var rootEditor: EditorView {
        if let parentEditor {
            return parentEditor.rootEditor
        }
        return self
    }

    /// `EditorView` containing the current `EditorView` in an `Attachment`
    public var parentEditor: EditorView? {
        containerAttachment?.containerEditorView
    }

    /// Clears the contents in the Editor.
    public func clear() {
        self.attributedText = NSAttributedString()
    }

    /// The auto-capitalization style for the text object.
    /// default is `UITextAutocapitalizationTypeSentences`
    public var autocapitalizationType: UITextAutocapitalizationType {
        get { richTextView.autocapitalizationType }
        set { richTextView.autocapitalizationType = newValue }
    }

    /// The autocorrection style for the text object.
    /// default is `UITextAutocorrectionTypeDefault`
    public var autocorrectionType: UITextAutocorrectionType {
        get { richTextView.autocorrectionType }
        set { richTextView.autocorrectionType = newValue }
    }

    /// The spell-checking style for the text object.
    public var spellCheckingType: UITextSpellCheckingType {
        get { richTextView.spellCheckingType }
        set { richTextView.spellCheckingType = newValue }
    }

    /// The configuration state for smart quotes.
    public var smartQuotesType: UITextSmartQuotesType {
        get { richTextView.smartQuotesType }
        set { richTextView.smartQuotesType = newValue }
    }

    /// The configuration state for smart dashes.
    public var smartDashesType: UITextSmartDashesType {
        get { richTextView.smartDashesType }
        set { richTextView.smartDashesType = newValue }
    }

    /// The configuration state for the smart insertion and deletion of space characters.
    public var smartInsertDeleteType: UITextSmartInsertDeleteType {
        get { richTextView.smartInsertDeleteType }
        set { richTextView.smartInsertDeleteType = newValue }
    }

    /// The keyboard style associated with the text object.
    public var keyboardType: UIKeyboardType {
        get { richTextView.keyboardType }
        set { richTextView.keyboardType = newValue }
    }

    /// The appearance style of the keyboard that is associated with the text object
    public var keyboardAppearance: UIKeyboardAppearance {
        get { richTextView.keyboardAppearance }
        set { richTextView.keyboardAppearance = newValue }
    }

    /// The visible title of the Return key.
    public var returnKeyType: UIReturnKeyType {
        get { richTextView.returnKeyType }
        set { richTextView.returnKeyType = newValue }
    }

    /// A Boolean value indicating whether the Return key is automatically enabled when the user is entering text.
    /// default is `NO` (when `YES`, will automatically disable return key when text widget has zero-length contents, and will automatically enable when text widget has non-zero-length contents)
    public var enablesReturnKeyAutomatically: Bool {
        get { richTextView.enablesReturnKeyAutomatically }
        set { richTextView.enablesReturnKeyAutomatically = newValue }
    }

    /// Identifies whether the text object should disable text copying and in some cases hide the text being entered.
    /// default is `NO`
    public var isSecureTextEntry: Bool {
        get { richTextView.isSecureTextEntry }
        set { richTextView.isSecureTextEntry = newValue }
    }

    /// The semantic meaning expected by a text input area.
    /// The textContentType property is to provide the keyboard with extra information about the semantic intent of the text document.
    /// default is `nil`
    public var textContentType: UITextContentType! {
        get { richTextView.textContentType }
        set { richTextView.textContentType = newValue }
    }

    /// A Boolean value indicating whether the text view allows the user to edit style information.
    public var allowsEditingTextAttributes: Bool {
        get { richTextView.allowsEditingTextAttributes }
        set { richTextView.allowsEditingTextAttributes = newValue }
    }

    /// A Boolean value indicating whether the receiver is selectable.
    /// This property controls the ability of the user to select content and interact with URLs and text attachments. The default value is true.
    public var isSelectable: Bool {
        get { richTextView.isSelectable }
        set { richTextView.isSelectable = newValue }
    }

    /// A text drag delegate object for customizing the drag source behavior of a text view.
    public var textDragDelegate: UITextDragDelegate? {
        get { richTextView.textDragDelegate }
        set { richTextView.textDragDelegate = newValue }
    }

    /// The text drop delegate for interacting with a drop activity in the text view.
    public var textDropDelegate: UITextDropDelegate? {
        get { richTextView.textDropDelegate }
        set { richTextView.textDropDelegate = newValue }
    }

    private func getAttachmentContentView(view: UIView?) -> AttachmentContentView? {
        guard let view = view else { return nil }
        if let attachmentContentView = view.superview as? AttachmentContentView {
            return attachmentContentView
        }
        return getAttachmentContentView(view: view.superview)
    }

    private func setup() {
        maxHeight = .default
        richTextView.autocorrectionType = .default

        richTextView.translatesAutoresizingMaskIntoConstraints = false
        richTextView.defaultTextFormattingProvider = self
        richTextView.richTextViewDelegate = self
        richTextView.richTextViewListDelegate = self

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
        AggregateEditorViewDelegate.editor(self, isReady: false)

        attachmentRenderingScheduler.delegate = self
    }

    /// Subclasses can override it to perform additional actions whenever the window changes.
    /// - IMPORTANT: Overriding implementations must call `super.didMoveToWindow()`
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if let pendingAttributedText {
            attributedText = pendingAttributedText
        }
        let isReady = window != nil
        AggregateEditorViewDelegate.editor(self, isReady: isReady)
    }

    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - Parameter size: The size for which the view should calculate its best-fitting size.
    /// - Returns:
    /// A new size that fits the receiver’s subviews.
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return richTextView.sizeThatFits(size)
    }

    /// Adds an interaction to the view.
    /// - Parameter interaction: The interaction object to add to the view.
    open override func addInteraction(_ interaction: UIInteraction) {
        richTextView.addInteraction(interaction)
    }

    /// Asks UIKit to make this object the first responder in its window.
    /// - Returns:
    /// `true` if this object is now the first-responder or `false` if it is not.
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return richTextView.becomeFirstResponder()
    }

    /// Denotes of the Editor is first responder
    /// - Returns: true, if is first responder
    public func isFirstResponder() -> Bool {
        richTextView.isFirstResponder
    }

    /// Resets typing attributes back to default text color, font and paragraph style.
    ///All other attributes are dropped.
    open func resetTypingAttributes() {
        richTextView.resetTypingAttributes()
    }

    public func attachmentsInRange(_ range: NSRange) -> [AttachmentRange] {
        guard range.endLocation <= attributedText.length else { return [] }
        let substring = attributedText.attributedSubstring(from: range)
        return substring.attachmentRanges
    }

    /// Converts given range to `UITextRange`, if valid
    /// - Parameter range: Range to convert
    /// - Returns: `UITextRange` representation of provided NSRange, if valid.
    public func textRange(from range: NSRange) -> UITextRange? {
        range.toTextRange(textInput: richTextView)
    }

    /// Cancels any pending rendering when async rendering of attachment is schedules.
    /// - Note:
    /// Asynchronous rendering is opt-in feature scheduled by providing `asyncAttachmentRenderingDelegate` to `EditorView`
    public func cancelPendingAsyncRendering() {
        attachmentRenderingScheduler.cancel()
    }

    /// The range of currently marked text in a document.
    /// If there is no marked text, the value of the property is `nil`. Marked text is provisionally inserted text that requires user confirmation; it occurs in multistage text input. The current selection, which can be a caret or an extended range, always occurs within the marked text.
    public var markedRange: NSRange? {
        guard let range = richTextView.markedTextRange else { return nil }
        let location = richTextView.offset(from: richTextView.beginningOfDocument, to: range.start)
        let length = richTextView.offset(from: range.start, to: range.end)
        // It returns `NSRange`, because `UITextPosition` is not very helpful without having access to additional methods and properties.
        return NSRange(location: location, length: length)
    }

    public func setAttributes(_ attributes: [NSAttributedString.Key: Any], at range: NSRange) {
//        self.richTextView.setAttributes(attributes, range: range)
//        self.richTextView.enumerateAttribute(.attachment, in: range, options: .longestEffectiveRangeNotRequired) { value, rangeInContainer, _ in
//            if let attachment = value as? Attachment {
//                attachment.addedAttributesOnContainingRange(rangeInContainer: rangeInContainer, attributes: attributes)
//            }
//        }
    }

    /// Returns the full attributed text contained in the `EditorView` along with the ones in editors nested in contained Attachments.
    /// - Parameter attachmentContentIdentifier: Identifier for opening and closing ranges for Attachment Content
    /// - Returns: Full attributed text
    /// - Note: An additional attribute with value of `Attachment.name` is automatically added with key `NSAttributedString.Key.viewOnly`.
    /// This can be changed by overriding default implementation of `getFullTextRangeIdentificationAttributes()` in `Attachment`.
    public func getFullAttributedText(using attachmentContentIdentifier: AttachmentContentIdentifier, in range: NSRange? = nil) -> NSAttributedString {
        let text = NSMutableAttributedString()
        let rangeToUse = range ?? attributedText.fullRange
        let substring = attributedText.attributedSubstring(from: rangeToUse)
        substring.enumerateAttribute(.attachment, in: substring.fullRange) { value, range, _ in
            if let attachment = value as? Attachment {
                let attachmentID = attachment.getFullTextRangeIdentificationAttributes()
                attachment.contentEditors.forEach { editor in
                    let editorText = NSMutableAttributedString(attributedString: editor.getFullAttributedText(using: attachmentContentIdentifier))
                    let openingID = attachmentContentIdentifier.openingID.addingAttributes(attachmentID)
                    let closingID = attachmentContentIdentifier.closingID.addingAttributes(attachmentID)

                    editorText.insert(openingID, at: 0)
                    editorText.insert(closingID, at: editorText.length)
                    text.append(editorText)
                }
            } else {
                let string = NSMutableAttributedString(attributedString: substring.attributedSubstring(from: range))
                text.append(string)
            }
        }
        return text
    }

    /// Sets async text resolution to resolve on next text layout pass.
    /// - Note: Changing attributes also causes layout pass to be performed, and this any applicable `AsyncTextResolvers` will be executed.
    public func setNeedsAsyncTextResolution() {
        needsAsyncTextResolution = true
    }

    /// Invokes async text resolution to resolve on demand.
    public func resolveAsyncTextIfNeeded() {
        needsAsyncTextResolution = true
        resolveAsyncText()
    }

    /// Returns the range of character at the given point
    /// - Parameter point: Point to get range from
    /// - Returns: Character range if available, else nil
    public func rangeOfCharacter(at point: CGPoint) -> NSRange? {
        let location = richTextView.convert(point, from: self)
        return richTextView.rangeOfCharacter(at: location)
    }

    /// Gets the lines separated by newline characters from the given range.
    /// - Parameter range: Range to get lines from.
    /// - Returns: Array of `EditorLine` from the given content range.
    /// - Note:
    /// Lines returned from this function do not contain terminating newline character in the text content.
    public func contentLinesInRange(_ range: NSRange) -> [EditorLine] {
        return richTextView.contentLinesInRange(range)
    }

    /// Gets the previous line of content from the given location. A content line is defined by the presence of a
    /// newline character.
    /// - Parameter location: Location to find line from, in reverse direction
    /// - Returns: Content line if a newline character exists before the current location, else nil
    public func previousContentLine(from location: Int) -> EditorLine? {
        return richTextView.previousContentLine(from: location)
    }

    /// Gets the next line of content from the given location. A content line is defined by the presence of a
    /// newline character.
    /// - Parameter location: Location to find line from, in forward direction
    /// - Returns: Content line if a newline character exists after the current location, else nil
    public func nextContentLine(from location: Int) -> EditorLine? {
        return richTextView.nextContentLine(from: location)
    }

    /// Gets the line preceding the given line. Nil if the given line is invalid or is first line
    /// - Parameter line: Reference line
    /// - Returns:
    /// `EditorLine` after the given line. Nil if the Editor is empty or given line is last line in the Editor.
    public func layoutLineAfter(_ line: EditorLine) -> EditorLine? {
        let lineRange = line.range
        let nextLineStartRange = NSRange(location: lineRange.location + lineRange.length + 1, length: 0)
        guard nextLineStartRange.isValidIn(richTextView) else { return nil }
        return editorLayoutLineFrom(range: nextLineStartRange)
    }

    /// Gets the line before the given line. Nil if the given line is invalid or is first line
    /// - Parameter line: Reference line
    /// - Returns:
    /// `EditorLine` before the given line. Nil if the Editor is empty or given line is first line in the Editor.
    public func layoutLineBefore(_ line: EditorLine) -> EditorLine? {
        let lineRange = line.range
        let previousLineStartRange = NSRange(location: lineRange.location - 1, length: 0)
        guard previousLineStartRange.isValidIn(richTextView) else { return nil }
        return editorLayoutLineFrom(range: previousLineStartRange)
    }

    private func editorLayoutLineFrom(range: NSRange?) -> EditorLine? {
        guard let range = range,
              let lineRange = richTextView.lineRange(from: range.location),
              contentLength >= lineRange.endLocation
        else { return nil }

        let text = attributedText.attributedSubstring(from: lineRange)
        return EditorLine(text: text, range: lineRange)
    }

    /// Returns the rectangles for line fragments spanned by the range. Based on the span of the range,
    /// multiple rectangles may be returned.
    /// - Parameter range: Range to be queried.
    /// - Returns:
    /// Array of rectangles for the given range.
    public func rects(for range: NSRange) -> [CGRect] {
        richTextView.rects(for: range)
    }

    /// Returns the range of text in the given rect.
    /// - Parameters:
    ///   - rect: Rect to get range from
    ///   - performingLayout: If `true`, layout is performed before returning the range. Defaults to `false`
    /// - Returns: Range for the given rect. `nil` if range is queried before layout has begun.
    /// - Note:
    /// This function returns a contiguous glyph range containing all glyphs that would need to be displayed in order to draw all glyphs that fall (even partially) within the bounding rect given.
    /// This range might include glyphs which do not fall into the rect at all.  At most this will return the glyph range for the whole container.
    /// When `performingLayout` is set to true, it will not generate glyphs or perform layout in attempting to answer, and thus may not be entirely correct.
    /// Bounding rects are always in container coordinates.
    public func rangeForRect(_ rect: CGRect, performingLayout: Bool = false) -> NSRange? {
        richTextView.rangeForRect(rect, performingLayout: performingLayout)
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
        let rect = richTextView.caretRect(for: textPosition)
        return convert(rect, from: richTextView)
    }

    /// Gets the word from text at given location in editor content
    /// - Parameter location: Location to be queried.
    /// - Returns:
    /// Word  at the given location. Nil is there's no content.
    public func word(at location: Int) -> NSAttributedString? {
        return richTextView.wordAt(location)
    }

    /// Gets the full range of attribute at given location.
    /// - Parameters:
    ///   - attribute: Attribute to search for
    ///   - location: Location for the attribute. Location may lie anywhere in the range of attribute.
    /// - Returns: Full range encompassing the given location. `nil` if attribute does not exist.
    public func attributeRangeFor(_ attribute: NSAttributedString.Key, at location: Int) -> NSRange? {
        guard location < attributedText.length else { return nil }
        var range = NSRange()
        let value = attributedText.attribute(attribute, at: location, longestEffectiveRange: &range, in: NSRange(location: 0, length: attributedText.length))
        guard value != nil else { return nil }
        return range
    }

    /// Deletes text backwards
    public func deleteBackward() {
        richTextView.deleteBackward()
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
    public func setFocus(at range: NSRange? = nil) {
        if let range {
            selectedRange = range
        }
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

    /// Invalidates the display of content at the given range.
    /// - Parameter range: Range to invalidate.
    public func invalidateDisplay(for range: NSRange) {
        richTextView.invalidateDisplay(for: range)
    }

    /// Invalidates the layout of content at the given range. This will also fore layout of any `Attachment` contained in the given range.
    /// - Parameter range: Range to invalidate.
    public func invalidateLayout(for range: NSRange) {
        richTextView.invalidateLayout(for: range)
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
        if registeredCommands?.isEmpty == true {
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

    /// Relayout `EditorView` on demand. This may be required if the size appears incorrect, for e..g. when hosted in an ScrollView
    /// - Parameter size: Size to use for relayout. When nil, default bounds are used.
    public func relayout(size: CGSize? = nil) {
        richTextView.recalculateHeight(size: size)
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return richTextView.canPerformAction(action, withSender: sender)
    }

    /// Determines if the given menu action can be invoked.
    /// - Parameters:
    ///   - action: Action to be invoked
    ///   - sender: Sender of the action
    /// - Returns:
    /// `true` to invoke default behaviour.
    /// `false` to conditionally disable/hide menu item. Display of menu item still depends on the context. E.g. Select is not shown
    /// in case the editor is empty.
    open func canPerformMenuAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return true
    }

    /// This method attempt to simulate the `paste` method but with explicitly provided attributed string and insertion range.
    /// - Parameters:
    ///   - attributedString: Attributed string to be inserted
    ///   - range: Insertion range
    /// - Returns:
    /// `true` The paste operation was successful
    /// `false` The paste operation was discarded
    open func paste(attributedString: NSAttributedString, into range: NSRange) -> Bool {
        let insertionRange: NSRange
        let length = contentLength

        if range.location < length {
            insertionRange = range
        } else {
            // In case we're out of bounds, avoid a crash.
            insertionRange = NSRange(location: length, length: 0)
        }

        let textViewDelegate = context as UITextViewDelegate

        if let shouldChange = textViewDelegate.textView?(
            richTextView,
            shouldChangeTextIn: insertionRange,
            replacementText: attributedString.string
        ) {
            guard shouldChange else { return false }
        }

        let newSelectedRange = NSRange(
            location: insertionRange.location + attributedString.length,
            length: 0
        )

        replaceCharacters(in: insertionRange, with: attributedString)
        selectedRange = newSelectedRange
        // Proton uses notifications from `UITextViewDelegate` to notify `EditorViewDelegate`,
        // but in case of changing `UITextView` content in code
        // `textViewDidChange` callback won't be triggered.
        // That's why delegate in this case should be notified manually.
        AggregateEditorViewDelegate.editor(self, didChangeTextAt: newSelectedRange)

        textViewDelegate.textViewDidChange?(richTextView)
        return true
    }

    private func updateBackgroundInheritingViews(color: UIColor?, oldColor: UIColor?) {
        let backgroundColorInheritingViews = attributedText.attachmentRanges.compactMap{ $0.attachment.contentView as? BackgroundColorObserving }
        backgroundColorInheritingViews.forEach {
            $0.containerEditor(self, backgroundColorUpdated: color, oldColor: oldColor)
        }
    }
}

extension EditorView {

    /// Adds given attributes to the range provided. If the range already contains a value for an attribute being provided,
    /// existing value will be overwritten by the new value provided in the attributes.
    /// - Parameters:
    ///   - attributes: Attributes to be added.
    ///   - range: Range on which attributes should be applied to.
    public func addAttributes(_ attributes: [NSAttributedString.Key: Any], at range: NSRange) {
        self.invalidateAttachmentSizeIfRequired(newAttributes: attributes, at: range)
        self.richTextView.addAttributes(attributes, range: range)
        // Check for range validity as enumerating over attachment hangs if the range is invalid
        guard range.isValidIn(self.richTextView) else { return }
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
        // Check for range validity as enumerating over attachment hangs if the range is invalid
        guard range.isValidIn(self.richTextView) else { return }
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

    func invalidateAttachmentSizeIfRequired(newAttributes: [NSAttributedString.Key: Any], at range: NSRange) {
        let attributedToCheck = [
            NSAttributedString.Key.paragraphStyle
        ]
        guard attributedToCheck.contains(where: { newAttributes[$0] != nil }) else { return }
        self.richTextView.enumerateAttribute(.attachment, in: range, options: .longestEffectiveRangeNotRequired) { value, rangeInContainer, _ in
            if let attachment = value as? Attachment {
                attachment.cachedBounds = nil
            }
        }
    }
}

extension EditorView: DefaultTextFormattingProviding { }

extension EditorView: RichTextViewListDelegate {
    var listLineFormatting: LineFormatting {
        return listFormattingProvider?.listLineFormatting ?? RichTextView.defaultListLineFormatting
    }

    func richTextView(_ richTextView: RichTextView, listMarkerForItemAt index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let defaultValue = NSAttributedString(string: "*", attributes: [.font: font])

        return listFormattingProvider?.listLineMarkerFor(editor: self, index: index, level: level, previousLevel: previousLevel, attributeValue: attributeValue) ?? .string(defaultValue)
    }
}

extension EditorView: RichTextViewDelegate {

    func richTextView(_ richTextView: RichTextView, didChangeSelection range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        AggregateEditorViewDelegate.editor(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }

    func richTextView(_ richTextView: RichTextView, shouldHandle key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange, handled: inout Bool) {
        AggregateEditorViewDelegate.editor(self, shouldHandle: key, modifierFlags: modifierFlags, at: range, handled: &handled)
    }

    func richTextView(_ richTextView: RichTextView, didReceive key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange) {
        textProcessor?.activeProcessors.forEach { processor in
            processor.handleKeyWithModifiers(editor: self, key: key, modifierFlags: modifierFlags, range: range)
        }
        AggregateEditorViewDelegate.editor(self, didReceiveKey: key, at: range)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange) {
        AggregateEditorViewDelegate.editor(self, didReceiveFocusAt: range)
    }

    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange) {
        AggregateEditorViewDelegate.editor(self, didLoseFocusFrom: range)
    }

    func richTextView(_ richTextView: RichTextView, didChangeTextAtRange range: NSRange) {
        AggregateEditorViewDelegate.editor(self, didChangeTextAt: range)
    }

    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool) {
        guard finished else { return }
        relayoutAttachments()
        resolveAsyncText()
        AggregateEditorViewDelegate.editor(self, didLayout: attributedText)
    }

    func richTextView(_ richTextView: RichTextView, selectedRangeChangedFrom oldRange: NSRange?, to newRange: NSRange?) {
        textProcessor?.activeProcessors.forEach { $0.selectedRangeChanged(editor: self, oldRange: oldRange, newRange: newRange) }
    }

    func richTextView(_ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        AggregateEditorViewDelegate.editor(self, didTapAtLocation: location, characterRange: characterRange)
    }

    func richTextView(_ richTextView: RichTextView, shouldSelectAttachmentOnBackspace attachment: Attachment) -> Bool? {
        AggregateEditorViewDelegate.editor(self, shouldSelectAttachmentOnBackspace: attachment)
    }
}

extension EditorView {
    func relayoutAttachments(in range: NSRange? = nil) {
        let rangeToUse = range ?? NSRange(location: 0, length: contentLength)
        richTextView.enumerateAttribute(.attachment, in: rangeToUse, options: .longestEffectiveRangeNotRequired) { [weak self] (attach, range, _) in
            guard let self,
                let attachment = attach as? Attachment else { return }

            if attachment.isImageBasedAttachment {
                attachment.setContainerEditor(self)
                return
            }

            guard let attachmentFrame = attachment.frame else { return }

            // Remove attachment from container if it is already added to another Editor
            // for e.g. when moving text with attachment into another attachment
            if attachment.containerEditorView != self {
                attachment.removeFromContainer()
            }

            let glyphRange = richTextView.glyphRange(forCharacterRange: range)
            var frame = richTextView.boundingRect(forGlyphRange: glyphRange)
            frame.origin.y += self.textContainerInset.top

            var size = attachmentFrame.size
            if size == .zero,
               let contentSize = attachment.contentView?.systemLayoutSizeFitting(bounds.size) {
                size = contentSize
            }

            var adjustedOrigin = frame.origin
            adjustedOrigin.x += textContainerInset.left
            frame = CGRect(origin: adjustedOrigin, size: size)

            if attachment.isRendered == false {
                attachment.isAsyncRendered = false
                if self.asyncAttachmentRenderingDelegate?.shouldRenderAsync(attachment: attachment) == true {
                    attachment.isRenderingAsync = true
                    self.attachmentRenderingScheduler.enqueue(id: attachment.id) {
                        // Because of async nature the attachment may get scheduled again to be rendered.
                        // ignore the attachments that are already rendered
                        guard attachment.isRendered == false else { return }
                        AggregateEditorViewDelegate.editor(self, willRenderAttachment: attachment)
                        attachment.render(in: self)
                        if attachment.needsDeferredRendering == false {
                            attachment.isAsyncRendered = true
                            self.asyncAttachmentRenderingDelegate?.didRenderAttachment(attachment, in: self)
                        }
                    }
                } else {
                    AggregateEditorViewDelegate.editor(self, willRenderAttachment: attachment)
                    attachment.render(in: self)
                    if !self.isSettingAttributedText, let focusable = attachment.contentView as? Focusable {
                        focusable.setFocus()
                    }
                    AggregateEditorViewDelegate.editor(self, didRenderAttachment: attachment)
                }
            }
            attachment.frame = frame
        }
        attachmentRenderingScheduler.executeNext()
    }
}

public extension EditorView {
    func resolveAsyncText() {
        guard needsAsyncTextResolution else { return }
        needsAsyncTextResolution = false
        var resolversInProgressCount = 0
        richTextView.enumerateAttribute(.asyncTextResolver, in: attributedText.fullRange, options: []) { [weak self] (resolverName, range, stop) in
            guard let self else {
                stop.pointee = true
                return
            }

            if let resolver = self.asyncTextResolvers.first(where: { $0.name == resolverName as? String }) {
                let string = NSMutableAttributedString(attributedString: self.attributedText.attributedSubstring(from: range))
                resolversInProgressCount += 1
                resolver.resolve(using: self, range: range, string: string) { [originalString = string] result in
                    resolversInProgressCount -= 1
                    switch result {
                    case .apply(let newString, let newRange):
                        let currentString = NSMutableAttributedString(attributedString: self.attributedText.attributedSubstring(from: range))
                        if originalString.string == currentString.string {
                            self.removeAttribute(.asyncTextResolver, at: range)
                            self.richTextView.replaceCharacters(in: newRange, with: newString)
                        }
                    case .discard:
                        self.removeAttribute(.asyncTextResolver, at: range)
                    }
                }
            }
        }
        // Enable next pass if there was any resolver in progress, else disable the next run.
        self.needsAsyncTextResolution = resolversInProgressCount > 0
    }
}

public extension EditorView {
    /// Determines if the given command can be executed on the current editor. The command is allowed to be executed if
    /// `requiresSupportedCommandsRegistration` is false or if the command has been registered with the editor.
    /// - Parameter command: Command to validate
    /// - Returns:
    /// `true` if the command is registered with the Editor.
    func isCommandRegistered(_ name: CommandName) -> Bool {
        return registeredCommands?.contains { $0.name == name } ?? true
    }
}

extension EditorView {
    func contains(range: NSRange) -> Bool {
        return range.location >= 0
        && range.length >= 0
        && range.upperBound <= contentLength
    }

    func clamp(range: NSRange) -> NSRange {
        range.clamped(upperBound: contentLength)
    }
}

extension EditorView: AsyncTaskSchedulerDelegate {
    func getIDsToPrioritize() -> [String] {
        guard let visibleRange else { return [] }
        let attachmentIDs = attachmentsInRange(visibleRange)
            .filter { $0.attachment.isPendingAsyncRendering }
            .map {  $0.attachment.id }

        guard attachmentIDs.isEmpty else {
            return attachmentIDs
        }
        self.renderedViewport = viewport
        // No attachments to render. Viewport rendering complete. Get attachments below viewport
        let nextRange = NSRange(location: visibleRange.endLocation, length: max(0, contentLength - visibleRange.endLocation - 1))
        let nextAttachmentIDs = attachmentsInRange(nextRange)
            .filter { $0.attachment.isPendingAsyncRendering }
            .map {  $0.attachment.id }

        guard nextAttachmentIDs.isEmpty else {
            return nextAttachmentIDs
        }

        let previousRange = NSRange(location: 0, length: visibleRange.location)
        let previousRangeIDs = attachmentsInRange(previousRange)
            .filter { $0.attachment.isPendingAsyncRendering }
            .map {  $0.attachment.id }

        return previousRangeIDs.reversed()
    }
}

extension EditorView {
    open override var forFirstBaselineLayout: UIView {
        richTextView
    }

    open override var forLastBaselineLayout: UIView {
        richTextView
    }
}
