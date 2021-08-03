//
//  NSFont.swift
//  NSFont
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

extension FontDescriptor.SymbolicTraits {
    static var traitBold: FontDescriptor.SymbolicTraits { .bold }
    static var traitItalic: FontDescriptor.SymbolicTraits { .italic }
    static var traitMonoSpace: FontDescriptor.SymbolicTraits { .monoSpace }
}

#endif
