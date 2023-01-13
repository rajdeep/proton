//
//  AutogrowingTextView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 31/12/19.
//  Copyright © 2019 Rajdeep Kwatra. All rights reserved.
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

class AutogrowingTextView: UITextView {

    var maxHeight: CGFloat = 0
    private var allowAutogrowing: Bool
    weak var boundsObserver: BoundsObserving?
    private var maxHeightConstraint: NSLayoutConstraint!
    private var heightAnchorConstraint: NSLayoutConstraint!
    private var isSizeRecalculationRequired = true

    init(frame: CGRect = .zero, textContainer: NSTextContainer? = nil, allowAutogrowing: Bool = false) {
        self.allowAutogrowing = allowAutogrowing
        super.init(frame: frame, textContainer: textContainer)
        isScrollEnabled = false
        heightAnchorConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: contentSize.height)
        heightAnchorConstraint.priority = .defaultHigh
        if allowAutogrowing {
            NSLayoutConstraint.activate([
                heightAnchorConstraint
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isScrollEnabled: Bool {
        didSet {
            // Invalidate intrinsic content size when scrolling is disabled again as a result of text
            // getting cleared/removed. In absence of the following code, the textview does not
            // resize when cleared until a character is typed in.
            guard isScrollEnabled == false,
                  oldValue == true
            else { return }
            
            invalidateIntrinsicContentSize()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard allowAutogrowing, maxHeight != .greatestFiniteMagnitude else { return }
        // Required to reset the size if content is removed
        if contentSize.height <= frame.height, isEditable {
            recalculateHeight()
            return
        }

        guard isSizeRecalculationRequired else { return }
        isSizeRecalculationRequired = false
        recalculateHeight()
    }

    private func recalculateHeight() {
        let bounds = self.bounds.integral
        let fittingSize = sizeThatFits(frame.size)
        self.isScrollEnabled = (fittingSize.height > bounds.height) || (self.maxHeight > 0 && self.maxHeight < fittingSize.height)
        heightAnchorConstraint.constant = min(fittingSize.height, contentSize.height)
    }

    override var bounds: CGRect {
        didSet {
            guard ceil(oldValue.height) != ceil(bounds.height) else { return }
            boundsObserver?.didChangeBounds(bounds, oldBounds: oldValue)
            isSizeRecalculationRequired = true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.becomeFirstResponder()
    }
}
