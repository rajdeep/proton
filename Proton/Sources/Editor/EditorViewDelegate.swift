//
//  EditorViewDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

public protocol EditorViewDelegate: AnyObject {
    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool)
    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange)
    func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange)
    func editor(_ editor: EditorView, didChangeTextAt range: NSRange)
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name)
}

public extension EditorViewDelegate {
    func editor(_: EditorView, didReceiveKey _: EditorKey, at _: NSRange, handled _: inout Bool) {}
    func editor(_: EditorView, didReceiveFocusAt _: NSRange) {}
    func editor(_: EditorView, didLoseFocusFrom _: NSRange) {}
    func editor(_: EditorView, didChangeTextAt _: NSRange) {}
    func editor(_: EditorView, didChangeSelectionAt _: NSRange, attributes _: [NSAttributedString.Key: Any], contentType _: EditorContent.Name) {}
}
