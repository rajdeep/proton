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

        if allowAutogrowing {
            heightAnchorConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: contentSize.height)
            heightAnchorConstraint.priority = .defaultHigh

            NSLayoutConstraint.activate([
                heightAnchorConstraint
            ])
        }
        //TODO: enable only when line numbering is turned on
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isScrollEnabled: Bool {
        didSet {
            guard oldValue != isScrollEnabled else { return }
            // If scrollEnabled is changed, reset contentOffset to .zero as without this
            // if the text close to keyboard is deleted, the first line of text may not be
            // entirely visible and with scroll being removed, it cannot be brought in focus manually by user
            if isScrollEnabled == false {
                contentOffset = .zero
            }
        }
    }

    override var contentSize: CGSize {
        didSet {
            guard oldValue != .zero,
                  contentSize != .zero,
                oldValue != contentSize else { return }
            // Entering a newline char may not always cause layout(super.layoutSubviews) to take place
            // This code is required to be run so that the isScrollEnabled state can be correctly calculated based
            // on the content size.
            recalculateHeightIfRequired()
        }
    }

    // Expose this method to the Objective-C runtime so clients
    // can dynamically change its implementation
    @objc dynamic func invalidateLayout() {
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard allowAutogrowing, maxHeight != .greatestFiniteMagnitude else { return }
        // Required to reset the size if content is removed
        if recalculateHeightIfRequired() {
            return
        }

        guard isSizeRecalculationRequired else { return }
        isSizeRecalculationRequired = false
        recalculateHeight()
    }

    @discardableResult
    func recalculateHeightIfRequired() -> Bool {
        guard contentSize.height <= frame.height else {
            return false
        }

        recalculateHeight()
        invalidateIntrinsicContentSize()
        return true
    }

    func recalculateHeight(size: CGSize? = nil) {
        guard allowAutogrowing else { return }
        let bounds = self.bounds.integral
        let sizeToUse = size ?? frame.size
        let fittingSize = self.calculatedSize(attributedText: attributedText, frame: sizeToUse, textContainerInset: textContainerInset)

        self.isScrollEnabled = (fittingSize.height > (bounds.height - contentInset.bottom)) || (self.maxHeight > 0 && self.maxHeight < fittingSize.height)
        self.heightAnchorConstraint?.constant = min(fittingSize.height, self.contentSize.height)

    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var fittingSize = calculatedSize(attributedText: attributedText, frame: size, textContainerInset: textContainerInset)
        if maxHeight > 0 {
            fittingSize.height = min(maxHeight, fittingSize.height)
        }
        return fittingSize
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

    private func calculatedSize(attributedText: NSAttributedString, frame: CGSize, textContainerInset: UIEdgeInsets) -> CGSize {
        DispatchQueue.global(qos: .userInteractive).sync { [lineFragmentPadding = textContainer.lineFragmentPadding ]  in
            // Adjust for horizontal paddings in textview to exclude from overall available width for attachment
            let horizontalAdjustments = (lineFragmentPadding * 2) + (textContainerInset.left + textContainerInset.right)
            let boundingRect = attributedText.boundingRect(with: CGSize(width: frame.width - horizontalAdjustments, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil).integral

            let insets = UIEdgeInsets(top: -textContainerInset.top, left: -textContainerInset.left, bottom: -textContainerInset.bottom, right: -textContainerInset.right)
            return boundingRect.inset(by: insets).size
        }
    }
}
