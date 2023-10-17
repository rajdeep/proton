//
//  AggregateEditorViewDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 20/7/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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

class AggregateEditorViewDelegate: EditorViewDelegate {
    private init(){ }

    static func editor(_ editor: EditorView, shouldHandle key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange, handled: inout Bool) {
        editor.delegate?.editor(editor, shouldHandle: key, modifierFlags: modifierFlags, at: range, handled: &handled)
        editor.editorContextDelegate?.editor(editor, shouldHandle: key, modifierFlags: modifierFlags, at: range, handled: &handled)
    }

    static func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange) {
        editor.delegate?.editor(editor, didReceiveKey: key, at: range)
        editor.editorContextDelegate?.editor(editor, didReceiveKey: key, at: range)
    }

    static func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) {
        editor.delegate?.editor(editor, didReceiveFocusAt: range)
        editor.editorContextDelegate?.editor(editor, didReceiveFocusAt: range)
    }

    static func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange) {
        editor.delegate?.editor(editor, didLoseFocusFrom: range)
        editor.editorContextDelegate?.editor(editor, didLoseFocusFrom: range)
    }

    static func editor(_ editor: EditorView, didChangeTextAt range: NSRange) {
        editor.delegate?.editor(editor, didChangeTextAt: range)
        editor.editorContextDelegate?.editor(editor, didChangeTextAt: range)
    }

    static func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        editor.delegate?.editor(editor, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
        editor.editorContextDelegate?.editor(editor, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }

    static func editor(_ editor: EditorView, didExecuteProcessors processors: [TextProcessing], at range: NSRange) {
        editor.delegate?.editor(editor, didExecuteProcessors: processors, at: range)
        editor.editorContextDelegate?.editor(editor, didExecuteProcessors: processors, at: range)
    }

    static func editor(_ editor: EditorView, didChangeSize currentSize: CGSize, previousSize: CGSize) {
        editor.delegate?.editor(editor, didChangeSize: currentSize, previousSize: previousSize)
        editor.editorContextDelegate?.editor(editor, didChangeSize: currentSize, previousSize: previousSize)
    }

    static func editor(_ editor: EditorView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        editor.delegate?.editor(editor, didTapAtLocation: location, characterRange: characterRange)
        editor.editorContextDelegate?.editor(editor, didTapAtLocation: location, characterRange: characterRange)
    }

    static func editor(_ editor: EditorView, didLayout content: NSAttributedString) {
        editor.delegate?.editor(editor,didLayout: content)
        editor.editorContextDelegate?.editor(editor,didLayout: content)
    }

    static func editor(_ editor: EditorView, willSetAttributedText attributedText: NSAttributedString, isDeferred: Bool) {
        editor.delegate?.editor(editor, willSetAttributedText: attributedText, isDeferred: isDeferred)
        editor.editorContextDelegate?.editor(editor, willSetAttributedText: attributedText, isDeferred: isDeferred)
    }

    static func editor(_ editor: EditorView, didSetAttributedText attributedText: NSAttributedString, isDeferred: Bool) {
        editor.delegate?.editor(editor, didSetAttributedText: attributedText, isDeferred: isDeferred)
        editor.editorContextDelegate?.editor(editor, didSetAttributedText: attributedText, isDeferred: isDeferred)
    }

    static func editor(_ editor: EditorView, isReady: Bool) {
        editor.delegate?.editor(editor, isReady: isReady)
        editor.editorContextDelegate?.editor(editor, isReady: isReady)
    }

    static func editor(_ editor: EditorView, didChangeEditable isEditable: Bool) {
        editor.delegate?.editor(editor, didChangeEditable: isEditable)
        editor.editorContextDelegate?.editor(editor, didChangeEditable: isEditable)
    }

    static func editor(_ editor: EditorView, didRenderAttachment attachment: Attachment) {
        editor.delegate?.editor(editor, didRenderAttachment: attachment)
        editor.editorContextDelegate?.editor(editor, didRenderAttachment: attachment)
    }
}
