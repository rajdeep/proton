//
//  HighlightTextCommand.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public extension NSAttributedString.Key {
    static let isHighlighted = NSAttributedString.Key("IsHighlighted")
}

public class HighlightTextCommand: RendererCommand {
    public var color = UIColor(red: 1.0, green: 0.98, blue: 0.80, alpha: 1.0)
    public init() { }
    public func execute(on renderer: RendererView) {
        let highligtedColor = renderer.selectedText.attribute(.isHighlighted, at: 0, effectiveRange: nil) as? UIColor

        guard highligtedColor != color else {
            renderer.removeAttributes([.backgroundColor, .isHighlighted], at: renderer.selectedRange)
            return
        }

        renderer.addAttributes([
            NSAttributedString.Key.backgroundColor : color,
            .isHighlighted: true
            ],at: renderer.selectedRange)
    }
}

