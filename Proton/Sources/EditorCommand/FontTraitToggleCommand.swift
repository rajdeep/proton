//
//  FontTraitToggleCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public class FontTraitToggleCommand: EditorCommand {
    public let trait: UIFontDescriptor.SymbolicTraits

    public init(trait: UIFontDescriptor.SymbolicTraits) {
        self.trait = trait
    }

    public func execute(on editor: EditorView) {
        let selectedText = editor.selectedText
        if editor.isEmpty || editor.selectedRange == .zero {
            guard let font = editor.typingAttributes[.font] as? UIFont else { return }
            editor.typingAttributes[.font] = font.toggled(trait: trait)
            return
        }

        if selectedText.length == 0 {
            guard
                let font = editor.attributedText.attribute(
                    .font, at: editor.selectedRange.location - 1, effectiveRange: nil) as? UIFont
            else { return }
            editor.typingAttributes[.font] = font.toggled(trait: trait)
            return
        }

        guard let initFont = selectedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        else {
            return
        }

        editor.attributedText.enumerateAttribute(
            .font, in: editor.selectedRange, options: .longestEffectiveRangeNotRequired
        ) { font, range, _ in
            if let font = font as? UIFont {
                let fontToApply = initFont.contains(trait: trait)
                    ? font.removing(trait: trait) : font.adding(trait: trait)
                editor.addAttribute(.font, value: fontToApply, at: range)
            }
        }
    }
}
