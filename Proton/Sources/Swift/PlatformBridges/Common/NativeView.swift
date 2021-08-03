//
//  NativeView.swift
//  NativeView
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension NativeView {
    var caLayer: CALayer {
        #if os(iOS)
        layer
        #else
        wantsLayer = true
        return layer!
        #endif
    }
    
    func setBackgroundColor(_ color: PlatformColor?) {
        #if os(iOS)
        backgroundColor = color
        #else
        wantsLayer = true
        layer?.backgroundColor = color?.cgColor
        #endif
    }
    
}
