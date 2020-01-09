//
//  EditorViewDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

public protocol EditorViewDelegate: class {
    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool)
    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange)
    func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange)
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [EditorAttribute], contentType: EditorContent.Name)
}

public extension EditorViewDelegate {
    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) { }
    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) { }
    func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange) { }
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [EditorAttribute], contentType: EditorContent.Name) { }
}
