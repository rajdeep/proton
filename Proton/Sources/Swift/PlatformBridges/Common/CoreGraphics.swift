//
//  CoreGraphics.swift
//  CoreGraphics
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

func GetCurrentGraphicsContext() -> CGContext? {
#if os(iOS)
    UIGraphicsGetCurrentContext()
#else
    NSGraphicsContext.current?.cgContext
#endif
}
