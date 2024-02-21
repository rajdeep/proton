//
//  ExpandableViewAttachment.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 21/5/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
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

import Proton

class ExpandableAttachment: Attachment {
    var view: ExpandableView

    init(frame: CGRect) {
        view = ExpandableView(frame: frame)
        super.init(view, size: .fullWidth)
        view.boundsObserver = self
        selectOnTap = true
    }

    var attributedText: NSAttributedString {
        get { view.attributedText }
        set { view.attributedText = newValue }
    }

    override func addedAttributesOnContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key: Any]) {
        var attributesWithoutParaStyle = attributes
        // Do not carry over para/list styles to Expand content as it may be inconsistent based on outer content
        attributesWithoutParaStyle[.paragraphStyle] = nil
        attributesWithoutParaStyle[.listItem] = nil
        view.editor.addAttributes(attributesWithoutParaStyle, at: view.editor.attributedText.fullRange)
    }

    override func removedAttributesFromContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key]) {
        view.editor.removeAttributes(attributes, at: view.editor.attributedText.fullRange)
    }
}
