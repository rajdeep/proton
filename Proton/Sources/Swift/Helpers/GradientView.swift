//
//  GradientView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 29/9/2022.
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

class GradientView: UIView {
    private var colors = [
        UIColor.black.cgColor,
        UIColor.white.cgColor
    ]

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init(colors:)")
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initGradientLayer()
    }

    @available(*, unavailable, message: "init(frame:) unavailable, use init(colors:)")
    override init(frame: CGRect) {
        super.init(frame: frame)
        initGradientLayer()
    }

    init(colors: [CGColor]) {
        super.init(frame: .zero)
        self.colors = colors
        initGradientLayer()
    }

    func initGradientLayer() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.colors = colors
    }
}
