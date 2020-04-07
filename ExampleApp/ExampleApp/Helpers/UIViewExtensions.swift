//
//  UIViewExtensions.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 8/2/20.
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
import UIKit

public extension UIView {
    func flash(numberOfFlashes: Float = 2, maxOpacity: Float = 0.5, minOpacity: Float = 0.1, onCompletion completion: ((UIView) -> Void)? = nil) {
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
        self.alpha = 1
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat], animations: {
            self.alpha = 0
        }, completion: nil)
    }
}
