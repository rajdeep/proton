//
//  NSColor.swift
//  NSColor
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

extension NSColor {
    static var systemBackground: PlatformColor {
        NSColor.textBackgroundColor
    }
}

#endif
