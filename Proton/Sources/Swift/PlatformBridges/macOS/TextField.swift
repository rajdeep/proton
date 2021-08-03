//
//  TextField.swift
//  TextField
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

public extension NSTextField {
    var attributedText: NSAttributedString? {
        get { attributedStringValue }
        set { attributedStringValue = newValue ?? NSAttributedString(string: "") }
    }
 
    var text: String? {
        get { stringValue }
        set { stringValue = newValue ?? "" }
    }
    
    var numberOfLines: Int {
        get { maximumNumberOfLines }
        set { maximumNumberOfLines = newValue }
    }
}

#endif
