//
//  NSView.swift
//  NSView
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

public extension NSView {
    
    func layoutIfNeeded() {
        if needsLayout {
            layout()
        }
    }
    
    func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return fittingSize
        fatalError()
        return fittingSize
    }
    
    var clipsToBounds: Bool {
        get { layer?.masksToBounds ?? false }
        set { layer?.masksToBounds = newValue }
    }
    
}

public extension NSView {
    var alpha: CGFloat {
        get { CGFloat(layer?.opacity ?? 1.0) }
        set { layer?.opacity = Float(newValue) }
    }
    
    func setNeedsLayout() {
        needsLayout = true
    }
}

#endif
