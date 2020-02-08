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
    func flash(numberOfFlashes: Float = 3, maxOpacity: Float = 0.7, minOpacity: Float = 0.1, onCompletion completion: ((UIView)->Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion?(self)
        }
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 0.2
        flash.fromValue = maxOpacity
        flash.toValue = minOpacity
        flash.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        flash.autoreverses = true
        flash.repeatCount = numberOfFlashes
        layer.add(flash, forKey: nil)
        CATransaction.commit()
    }
}
