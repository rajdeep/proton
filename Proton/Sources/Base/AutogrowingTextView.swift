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
    private let dimensionsCalculatingTextView = UITextView()

    private let growsInfinitely: Bool
    private var allowsAutogrowing: Bool { !growsInfinitely }
    var maxHeight: CGFloat = 0 {
        didSet {
            assert(maxHeight == 0 || allowsAutogrowing, "'.maxHeight' not allowed when '.growsInfinitely = true'")
            guard maxHeight > 0 else {
                maxHeightConstraint.isActive = false
                return
            }

            maxHeightConstraint.constant = maxHeight
            maxHeightConstraint.isActive = true
        }
    }

    weak var boundsObserver: BoundsObserving?
    private var maxHeightConstraint: NSLayoutConstraint!

    init(frame: CGRect, textContainer: NSTextContainer?, growsInfinitely: Bool) {
        self.growsInfinitely = growsInfinitely
        super.init(frame: frame, textContainer: textContainer)
        isScrollEnabled = false
        maxHeightConstraint = heightAnchor.constraint(lessThanOrEqualToConstant: frame.height)
        if allowsAutogrowing {
            NSLayoutConstraint.activate([
                heightAnchor.constraint(greaterThanOrEqualToConstant: frame.height)
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
            guard isScrollEnabled == false, oldValue == true else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard allowsAutogrowing else { return }
        let bounds = self.bounds
        updateDimensionsCalculatingTextView()
        let fittingSize = dimensionsCalculatingTextView.sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude))
        isScrollEnabled = (fittingSize.height > bounds.height) || (maxHeight > 0 && maxHeight < fittingSize.height)
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        updateDimensionsCalculatingTextView()
        var fittingSize = dimensionsCalculatingTextView.sizeThatFits(size)
        if maxHeight > 0 {
            fittingSize.height = min(maxHeight, fittingSize.height)
        }
        return fittingSize
    }

    override var bounds: CGRect {
        didSet {
            guard oldValue.height != bounds.height else { return }
            boundsObserver?.didChangeBounds(bounds)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.becomeFirstResponder()
    }

    private func updateDimensionsCalculatingTextView() {
        dimensionsCalculatingTextView.font = font
        dimensionsCalculatingTextView.attributedText = attributedText
        dimensionsCalculatingTextView.textContainerInset = textContainerInset
    }
}
