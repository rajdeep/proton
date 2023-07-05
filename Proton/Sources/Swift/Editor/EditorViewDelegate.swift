//
//  EditorViewDelegate.swift
//  Proton
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

/// Describes an object interested in listening to events raised from EditorView
public protocol EditorViewDelegate: AnyObject {

    /// Invoked when a special key like `enter`, `tab` etc. is intercepted in the `Editor`
    /// - Parameters:
    ///   - editor: Editor view receiving the event.
    ///   - key: Key that is intercepted.
    ///   - range: Range of the key in editor
    ///   - handled: Set to `true` to hijack the key press i.e. when `true`, the key press is not passed to the `Editor`
    func editor(_ editor: EditorView, shouldHandle key: EditorKey, at range: NSRange, handled: inout Bool)

    /// Invoked when a special key like `enter`, `tab` etc. is entered in the `Editor`
    /// - Parameters:
    ///   - editor: Editor view receiving the event.
    ///   - key: Key that is received.
    ///   - range: Range of the key in editor
    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange)

    /// Invoked when editor receives focus.
    /// - Parameters:
    ///   - editor:  Editor view receiving the event.
    ///   - range: Range where focus is received.
    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange)

    /// Invoked when editor loses the focus.
    /// - Parameters:
    ///   - editor:  Editor view receiving the event.
    ///   - range: Range from where focus is lost.
    func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange)

    /// Invoked when text is changed in editor.
    /// - Parameters:
    ///   - editor:  Editor view receiving the event.
    ///   - range: Range where text is modified.
    func editor(_ editor: EditorView, didChangeTextAt range: NSRange)

    /// Invoked when the selection range changes in the editor as a result of moving the cursor using keys/mouse or taps.
    /// - Parameters:
    ///   - editor:  Editor view receiving the event.
    ///   - range: Range where selection is changed.
    ///   - attributes: Attributes at the updated range.
    ///   - contentType: Name of the content at the updated range.
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name)

    /// Invoked when text processors are executed in the editor.
    /// - Parameters:
    ///   - editor:  Editor view receiving the event.
    ///   - processors: Processors that are executed.
    ///   - range: Range where processors are executed.
    func editor(_ editor: EditorView, didExecuteProcessors processors: [TextProcessing], at range: NSRange)

    /// Invoked when the size of EditorView changes.
    /// - Parameters:
    ///   - editor:  Editor view receiving the event.
    ///   - currentSize: Current size of Editor after updates.
    ///   - previousSize: Size of Editor before the update.
    func editor(_ editor: EditorView, didChangeSize currentSize: CGSize, previousSize: CGSize)

    /// Invoked when a location within the `EditorView` is tapped.
    /// - Parameters:
    ///   - editor:  Editor view receiving the event.
    ///   - location: Location of the tap event
    ///   - characterRange: Range of character at the tapped location, if available.
    func editor(_ editor: EditorView, didTapAtLocation location: CGPoint, characterRange: NSRange?)

    /// Invoked whenever layout pass completes as a result of changing or text or attributes
    /// - Parameters:
    ///   - editor: Editor view receiving the event.
    ///   - content: Attributed text value.
    func editor(_ editor: EditorView, didLayout content: NSAttributedString)

    /// Invoked before attributedText is set on the `EditorView`
    /// - Parameters:
    ///   - editor: Editor view receiving the event.
    ///   - attributedText: Attributed text value to be set.
    ///   - isDeferred: `true` if setter is called deferred owing to Editor not being on `window` when `attributedText` was originally set.
    func editor(_ editor: EditorView, willSetAttributedText attributedText: NSAttributedString, isDeferred: Bool)

    /// Invoked after attributedText is set on the `EditorView`
    /// - Parameters:
    ///   - editor: Editor view receiving the event.
    ///   - attributedText: Attributed text value set on the editor.
    ///   - isDeferred: `true` if setter is called deferred owing to Editor not being on `window` when `attributedText` was originally set.
    func editor(_ editor: EditorView, didSetAttributedText attributedText: NSAttributedString, isDeferred: Bool)

    /// Invoked when Editor has been added to the view hierarchy and is ready to receive events.
    /// - Parameters:
    ///   - editor: Editor view receiving the event.
    ///   - isReady: `true` if Editor is loaded. `false` when Editor is initialized but not yet in view hierarchy.
    func editor(_ editor: EditorView, isReady: Bool)

    /// Invoked when Editor's isEditable status is changed
    /// - Parameters:
    ///   - editor: Editor view receiving the event.
    ///   - isEditable: `true` if editor is editable, else `false`
    func editor(_ editor: EditorView, didChangeEditable isEditable: Bool)
}

public extension EditorViewDelegate {
    func editor(_ editor: EditorView, shouldHandle key: EditorKey, at range: NSRange, handled: inout Bool) { }
    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange) { }
    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) { }
    func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange) { }
    func editor(_ editor: EditorView, didChangeTextAt range: NSRange) { }
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) { }
    func editor(_ editor: EditorView, didExecuteProcessors processors: [TextProcessing], at range: NSRange) { }
    func editor(_ editor: EditorView, didChangeSize currentSize: CGSize, previousSize: CGSize) { }
    func editor(_ editor: EditorView, didTapAtLocation location: CGPoint, characterRange: NSRange?) { }
    func editor(_ editor: EditorView, didLayout content: NSAttributedString) { }
    func editor(_ editor: EditorView, willSetAttributedText attributedText: NSAttributedString, isDeferred: Bool) { }
    func editor(_ editor: EditorView, didSetAttributedText attributedText: NSAttributedString, isDeferred: Bool) { }
    func editor(_ editor: EditorView, isReady: Bool) { }
    func editor(_ editor: EditorView, didChangeEditable isEditable: Bool) { }
}
