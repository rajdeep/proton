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
    var delegate: EditorViewDelegate? { get set }

    func becomeFirstResponder() -> Bool
}

public extension EditorContentView {
    var attributedText: NSAttributedString {
        get { editor.attributedText }
        set { editor.attributedText = newValue }
    }

    func becomeFirstResponder() -> Bool {
        return editor.becomeFirstResponder()
    }

    var maxHeight: CGFloat {
        get { editor.maxHeight }
        set { editor.maxHeight = newValue }
    }

    var boundsObserver: BoundsObserving? {
        get { editor.boundsObserver }
        set { editor.boundsObserver = newValue }
    }

    var delegate: EditorViewDelegate? {
        get { editor.delegate }
        set { editor.delegate = newValue }
    }

    func setFocus() {
        editor.becomeFirstResponder()
    }
}
