//
//  NSAppearance.swift
//  NSAppearance
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

extension NSAppearance {
    var isDarkMode: Bool {
        name != NSAppearance.Name.aqua
    }
}

#endif

