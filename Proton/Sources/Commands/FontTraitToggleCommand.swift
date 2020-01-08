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
        guard let font = selectedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else { return }
        let toggledFont = font.toggle(trait: trait)
        editor.addAttribute(.font, value: toggledFont, at: editor.selectedRange)
    }
}
