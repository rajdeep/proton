//
//  NSLabel.swift
//  NSLabel
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

public class NSLabel: NSTextField {
    
    var attributedText: NSAttributedString? {
        get { attributedStringValue }
        set { attributedStringValue = newValue ?? NSAttributedString(string: "") }
    }
    var numberOfLines: Int {
        get { maximumNumberOfLines }
        set { maximumNumberOfLines = newValue }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        isEditable = false
        isBezeled = false
        backgroundColor = .white
        
        setContentHuggingPriority(.fittingSizeCompression, for: .vertical)
        setContentCompressionResistancePriority(.fittingSizeCompression, for: .vertical)
    }
}

#endif
