//
//  UITextView.swift
//  UITextView
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(iOS)
import UIKit

extension UITextView {
    var nsTextStorage: NSTextStorage! {
        get { textStorage }
    }
    var nsTextContainer: NSTextContainer! {
        get { textContainer }
    }
    var nsLayoutManager: NSLayoutManager! {
        get { layoutManager }
    }
    var textContainerEdgeInset: EdgeInsets {
        get { textContainerInset }
        set { textContainerInset = newValue }
    }
}
#endif
