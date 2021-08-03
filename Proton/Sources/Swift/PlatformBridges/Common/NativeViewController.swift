//
//  NativeViewController.swift
//  NativeViewController
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation

public extension NativeViewController {
    var unwrappedView: NativeView {
        #if os(iOS)
        self.view!
        #else
        self.view
        #endif
    }
}
