//
//  Utility.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/4/24.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
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

public class Utility {
    private init() { }

    public static func drawRect(rect: CGRect, color: UIColor, in view: UIView, name: String = "rect_layer") {
        let path = UIBezierPath(rect: rect).cgPath
        drawPath(path: path, color: color, in: view)
    }

    public static func drawPath(path: CGPath, color: UIColor, in view: UIView, name: String = "path_layer") {
        let existingLayer = view.layer.sublayers?.first(where: { $0.name == name}) as? CAShapeLayer
        let shapeLayer = existingLayer ?? CAShapeLayer()
        shapeLayer.path = path
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 1.0
        shapeLayer.name = name

        if existingLayer == nil {
            view.layer.addSublayer(shapeLayer)
        }
    }
}
