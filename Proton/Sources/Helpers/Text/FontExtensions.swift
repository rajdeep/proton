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

    func toggle(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        var traits = self.traits
        if traits.contains(trait) {
            traits.subtract(trait)
        } else {
            traits.formUnion(trait)
        }

        guard let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: updatedFontDescriptor, size: 0.0)
    }
}
