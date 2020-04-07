//
//  HighlightTextCommand.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
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

public extension NSAttributedString.Key {
    static let isHighlighted = NSAttributedString.Key("IsHighlighted")
}

public class HighlightTextCommand: RendererCommand {
    public let color = UIColor(dynamicProvider: { traightCollection -> UIColor in
        switch traightCollection.userInterfaceStyle {
        case .dark:
            return UIColor.systemYellow.withAlphaComponent(0.2)
        default:
            return UIColor(red: 1.0, green: 0.98, blue: 0.80, alpha: 1.0)
        }
    })
    public init() { }
    public func execute(on renderer: RendererView) {
        guard renderer.selectedText.length > 0 else { return }
        let highlightedColor = renderer.selectedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor

        guard highlightedColor != color else {
            renderer.removeAttributes([.backgroundColor, .isHighlighted], at: renderer.selectedRange)
            return
        }

        renderer.addAttributes([
            .backgroundColor: color,
            .isHighlighted: true,
        ], at: renderer.selectedRange)
    }
}
