//
//  KeyModifierFlags.swift
//  KeyModifierFlags
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

public struct KeyModifierFlags : OptionSet {
    
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let shift: KeyModifierFlags     = .init(rawValue: 1 << 17)
    public static let control: KeyModifierFlags   = .init(rawValue: 1 << 18)
    public static let alternate: KeyModifierFlags = .init(rawValue: 1 << 19)
    public static let command: KeyModifierFlags   = .init(rawValue: 1 << 20)

}
#endif
