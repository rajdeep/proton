//
//  AutogrowingTextField.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
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
        // TODO: revisit to use invalidate intrinsic content size
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
