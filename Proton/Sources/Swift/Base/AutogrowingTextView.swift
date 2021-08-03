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
#if os(iOS)
import UIKit
#else
import AppKit
#endif

class AutogrowingTextView: PlatformTextView {

    var maxHeight: CGFloat = 0 {
        didSet {
            guard maxHeight > 0,
                  maxHeight < .greatestFiniteMagnitude
            else {
                maxHeightConstraint.isActive = false
                return
            }

            maxHeightConstraint.constant = maxHeight
            maxHeightConstraint.isActive = true
        }
    }

    weak var boundsObserver: BoundsObserving?
    var maxHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        maxHeightConstraint = heightAnchor.constraint(lessThanOrEqualToConstant: frame.height)
        isScrollEnabled = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: frame.height)
        ])
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
        guard maxHeight != .greatestFiniteMagnitude else { return }
        let bounds = self.bounds.integral
        let fittingSize = self.calculatedSize(attributedText: attributedText, frame: frame, textContainerInset: textContainerEdgeInset)
        self.isScrollEnabled = (fittingSize.height > bounds.height) || (self.maxHeight > 0 && self.maxHeight < fittingSize.height)
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var fittingSize = calculatedSize(attributedText: attributedText, frame: frame, textContainerInset: textContainerEdgeInset)
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

    private func calculatedSize(attributedText: NSAttributedString, frame: CGRect, textContainerInset: EdgeInsets) -> CGSize {
        // Adjust for horizontal paddings in textview to exclude from overall available width for attachment
        let horizontalAdjustments = (nsTextContainer.lineFragmentPadding * 2) + (textContainerInset.left + textContainerInset.right)
        let boundingRect = attributedText.boundingRect(with: CGSize(width: frame.width - horizontalAdjustments, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil).integral

        let insets = EdgeInsets(top: -textContainerInset.top, left: -textContainerInset.left, bottom: -textContainerInset.bottom, right: -textContainerInset.right)
        
        return boundingRect.inset(by: insets).size
    }

}
