//
//  EditorContentView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public protocol EditorContentView: Focusable {
    var editor: EditorView { get }

    var attributedText: NSAttributedString { get set }
    var maxHeight: CGFloat { get set }
    var boundsObserver: BoundsObserving? { get set }

    func becomeFirstResponder() -> Bool
}

public extension EditorContentView {
    var attributedText: NSAttributedString {
        get { return editor.attributedText }
        set { editor.attributedText = newValue }
    }

    func becomeFirstResponder() -> Bool {
        return editor.becomeFirstResponder()
    }

    var maxHeight: CGFloat {
        get { return editor.maxHeight }
        set { editor.maxHeight = newValue }
    }

    var boundsObserver: BoundsObserving? {
        get { return editor.boundsObserver }
        set { editor.boundsObserver = newValue }
    }

    func setFocus() {
        editor.becomeFirstResponder()
    }
}


