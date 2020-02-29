//
//  FontExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public extension UIFont {

    var traits: UIFontDescriptor.SymbolicTraits {
        return fontDescriptor.symbolicTraits
    }

    var isBold: Bool {
        return traits.contains(.traitBold)
    }

    var isItalics: Bool {
        return traits.contains(.traitItalic)
    }

    var isMonoSpaced: Bool {
        return traits.contains(.traitMonoSpace)
    }

    var textStyle: UIFont.TextStyle {
        guard let style = fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.textStyle) as? String else {
            return .body
        }
        return UIFont.TextStyle(rawValue: style)
    }

    var isNonDynamicTextStyle: Bool {
        return textStyle.rawValue == "CTFontRegularUsage"
    }

    func contains(trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        return traits.contains(trait)
    }

    func toggled(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let updatedFont: UIFont
        if self.contains(trait: trait) {
            updatedFont = removing(trait: trait)
        } else {
            updatedFont = adding(trait: trait)
        }

        return updatedFont
    }

    func adding(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        var traits = self.traits
        traits.formUnion(trait)
        guard let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: updatedFontDescriptor, size: 0.0)
    }

    func removing(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        var traits = self.traits
        traits.subtract(trait)
        guard let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: updatedFontDescriptor, size: 0.0)
    }
}
