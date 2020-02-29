//
//  MockEditorViewDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

@testable import Proton

class MockEditorViewDelegate: EditorViewDelegate {
    var onSelectionChanged: ((EditorView, NSRange, [NSAttributedString.Key: Any], EditorContent.Name) -> Void)?
    var onKeyReceived: ((EditorView, EditorKey, NSRange, Bool) -> Void)?
    var onReceivedFocus: ((EditorView, NSRange) -> Void)?
    var onLostFocus: ((EditorView, NSRange) -> Void)?

    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        onSelectionChanged?(editor, range, attributes, contentType)
    }

    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) {
        onKeyReceived?(editor, key, range, handled)
    }

    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) {
        onReceivedFocus?(editor, range)
    }

    func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange) {
        onLostFocus?(editor, range)
    }
}
