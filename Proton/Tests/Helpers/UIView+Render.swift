//
//  UIView+Render.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func render() {
        setNeedsLayout()
        layoutIfNeeded()
    }

    func addBorder(_ color: UIColor = .black) {
        layer.borderColor = color.cgColor
        layer.borderWidth = 1.0
    }
}
