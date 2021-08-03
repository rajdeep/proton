//
//  NSRectCorner.swift
//  NSRectCorner
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

public struct NSRectCorner : OptionSet {
    
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let topLeft: NSRectCorner     = .init(rawValue: 1 << 0)
    public static var topRight: NSRectCorner    = .init(rawValue: 1 << 1)
    public static var bottomLeft: NSRectCorner  = .init(rawValue: 1 << 2)
    public static var bottomRight: NSRectCorner = .init(rawValue: 1 << 3)
    public static var allCorners: NSRectCorner  = .init(rawValue: UInt.max)
}

#endif
