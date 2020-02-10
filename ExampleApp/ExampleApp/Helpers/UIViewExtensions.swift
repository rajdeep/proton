//
//  UIViewExtensions.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 8/2/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    func flash(numberOfFlashes: Float = 2, maxOpacity: Float = 0.5, minOpacity: Float = 0.1, onCompletion completion: ((UIView)->Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion?(self)
        }
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 0.5
        flash.fromValue = maxOpacity
        flash.toValue = minOpacity
        flash.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        flash.autoreverses = true
        flash.repeatCount = numberOfFlashes
        layer.add(flash, forKey: nil)
        CATransaction.commit()
    }

    func blink() {
        self.alpha = 1;
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat], animations: {
            self.alpha = 0
        }, completion: nil)
    }
}
