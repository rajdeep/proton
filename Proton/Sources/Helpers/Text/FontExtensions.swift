//
//  FontExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {

    public var traits: UIFontDescriptor.SymbolicTraits {
        return fontDescriptor.symbolicTraits
    }

    public var isBold: Bool {
        return traits.contains(.traitBold)
    }

    public var isItalics: Bool {
        return traits.contains(.traitItalic)
    }

    public var isMonoSpaced: Bool {
        return traits.contains(.traitMonoSpace)
    }

    public var textStyle: UIFont.TextStyle {
        guard let style = fontDescriptor.object(forKey: .textStyle) as? String else {
            return .body
        }
        return UIFont.TextStyle(rawValue: style)
    }

    public var isNonDynamicTextStyle: Bool {
        return textStyle.rawValue == "CTFontRegularUsage"
    }

    public func contains(trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        return traits.contains(trait)
    }

    public func toggled(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let updatedFont: UIFont
        if self.contains(trait: trait) {
            updatedFont = removing(trait: trait)
        } else {
            updatedFont = adding(trait: trait)
        }

        return updatedFont
    }

    public func adding(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        var traits = self.traits
        traits.formUnion(trait)
        guard let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: updatedFontDescriptor, size: 0.0)
    }

    public func removing(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        var traits = self.traits
        traits.subtract(trait)
        guard let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: updatedFontDescriptor, size: 0.0)
    }
}
