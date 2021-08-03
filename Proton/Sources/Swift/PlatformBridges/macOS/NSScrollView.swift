//
//  NSScrollView.swift
//  NSScrollView
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

extension NSScrollView {
    
    var contentOffset: CGPoint {
        get { contentView.bounds.origin }
        set {
            guard contentView.bounds.origin != newValue else { return }
            contentView.bounds.origin = newValue
        }
    }
 
    func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        // TODO: macOS Animation macOS
        scrollToVisible(rect)
    }
    
}
#endif
