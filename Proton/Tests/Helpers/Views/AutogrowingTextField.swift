//
//  AutogrowingTextField.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class AutogrowingTextField: UITextField, UITextFieldDelegate {
    weak var boundsObserver: BoundsObserving?

    override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else { return }
            boundsObserver?.didChangeBounds(bounds)
        }
    }

    override var intrinsicContentSize: CGSize {
        let fittingSize = sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: frame.height))
        //TODO: revisit to use invalidate intrinsic content size
        self.bounds = CGRect(origin: bounds.origin, size: fittingSize)
        return fittingSize
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 4, dy: 4)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}

extension AutogrowingTextField: InlineContent {
    var name: EditorContent.Name {
        return EditorContent.Name(rawValue: "textField")
    }
}

extension AutogrowingTextField: Focusable {
    func setFocus() {
        becomeFirstResponder()
    }
}
