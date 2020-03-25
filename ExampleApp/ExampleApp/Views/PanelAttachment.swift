//
//  PanelAttachment.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 12/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class PanelAttachment: Attachment {
    var view: PanelView

    init(frame: CGRect) {
        view = PanelView(frame: frame)
        super.init(view, size: .fullWidth)
        view.delegate = self
        view.boundsObserver = self
    }

    var attributedText: NSAttributedString {
        get { view.attributedText }
        set { view.attributedText = newValue }
    }

    override func addedAttributesOnContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key: Any]) {
        view.editor.addAttributes(attributes, at: view.editor.attributedText.fullRange)
    }

    override func removedAttributesFromContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key]) {
        view.editor.removeAttributes(attributes, at: view.editor.attributedText.fullRange)
    }
}

extension PanelAttachment: PanelViewDelegate {
    func panel(_ panel: PanelView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        guard let containerEditor = self.containerEditorView else { return }
        containerEditor.delegate?.editor(containerEditor, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }

    func panel(_ panel: PanelView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) {
        if key == .backspace, range == .zero, panel.editor.attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            removeFromContainer()
            handled = true
        } else if key == .enter,
            let range = rangeInContainer()?.nextPosition,
            let containerBounds = containerBounds {
            let newAttachment = PanelAttachment(frame: CGRect(origin: .zero, size: CGSize(width: containerBounds.width, height: 30)))
            self.containerEditorView?.insertAttachment(in: range, attachment: newAttachment)
            handled = true
        }
    }
}
