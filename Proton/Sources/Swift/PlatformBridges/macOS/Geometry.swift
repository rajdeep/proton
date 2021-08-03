//
//  Geometry.swift
//  Geometry
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

extension CGRect {
    public func inset(by insets: NSEdgeInsets) -> CGRect {
        CGRect(x: minX + insets.left,
               y: minY + insets.top,
               width: width - insets.left - insets.right,
               height: height - insets.bottom - insets.top)
    }
}

#endif
