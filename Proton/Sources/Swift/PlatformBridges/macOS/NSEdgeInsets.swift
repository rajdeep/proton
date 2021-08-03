//
//  NSEdgeInsets.swift
//  NSEdgeInsets
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

extension NSEdgeInsets {
    static var zero = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}

#endif
