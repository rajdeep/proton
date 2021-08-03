//
//  TextView.swift
//  TextView
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

/// NSTextViewDelegate_Bridge is a bridge between NSTextViewDelegate and UITextViewDelegate
/// It transforms NSTextViewDelegate callbacks to the format of UITextViewDelegate.
protocol NSTextViewDelegate_Bridge: AnyObject {
    func textViewDidChangeSelection(_ textView: PlatformTextView)
    func textViewDidBeginEditing(_ textView: PlatformTextView)
    func textViewDidEndEditing(_ textView: PlatformTextView)
    func textView(_ textView: PlatformTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    func textViewDidChange(_ textView: PlatformTextView)
}

extension NSTextViewDelegate_Bridge {
    func textViewDidChangeSelection(_ textView: PlatformTextView) { }
    func textViewDidBeginEditing(_ textView: PlatformTextView) { }
    func textViewDidEndEditing(_ textView: PlatformTextView) { }
    func textView(_ textView: PlatformTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool { true }
    func textViewDidChange(_ textView: PlatformTextView) { }
}

class PlatformTextView: NSTextView, NSTextViewDelegate {
    weak var nsDelegateBridge: NSTextViewDelegate_Bridge?

    var attributedText: NSAttributedString! {
        get { attributedString() }
        set { textStorage?.setAttributedString(newValue) }
    }
    
    var textContentType: NSTextContentType {
        get { contentType! }
        set { contentType = newValue }
    }
    
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
        get {
            EdgeInsets(top: textContainerInset.height / 2.0,
                         left: textContainerInset.width / 2.0,
                         bottom: textContainerInset.height / 2.0,
                         right: textContainerInset.width / 2.0)
        }
        set {
            // TODO: macOS how to implement a proper inset
            // that supports different values for left/right?
            textContainerInset = NSSize(width: newValue.left + newValue.right,
                                                   height: newValue.top + newValue.bottom)
        }
    }
    
    var contentOffset: CGPoint {
        get { enclosingScrollView?.contentOffset ?? .zero  }
        set { enclosingScrollView?.contentOffset = newValue }
    }

    var contentInset: EdgeInsets {
        get { enclosingScrollView?.contentInsets ?? .zero }
        set { enclosingScrollView?.contentInsets = newValue }
    }
    
    // MARK: - UIView Bridge
    
    override func layout() {
        layoutSubviews()
        super.layout()
    }
    
    func layoutSubviews() {
        // ...
    }
    
    open func sizeThatFits(_ size: CGSize) -> CGSize {
        fittingSize
    }
    
    // MARK: - UIScrollView Bridge
    
    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        enclosingScrollView?.scrollRectToVisible(rect, animated: animated)
    }
    
    // MARK: - NSTextViewDelegate
    
    func textViewDidChangeSelection(_ notification: Notification) {
        nsDelegateBridge?.textViewDidChangeSelection(self)
    }
    
    func textDidBeginEditing(_ notification: Notification) {
        nsDelegateBridge?.textViewDidBeginEditing(self)
    }
    
    func textDidEndEditing(_ notification: Notification) {
        nsDelegateBridge?.textViewDidEndEditing(self)
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        nsDelegateBridge?.textView(self, shouldChangeTextIn: affectedCharRange, replacementText: replacementString ?? "") ?? true
    }
    
    func textDidChange(_ notification: Notification) {
        nsDelegateBridge?.textViewDidChange(self)
    }
    
    // MARK: - Responder commands
    
    @objc func deleteBackward() {
        super.deleteBackward(nil)
    }
        
    @objc func select(_ sender: Any?) {
        fatalError()
    }
        
    @objc func toggleUnderline(_ sender: Any?) {
        underline(sender)
    }
    
    @objc func toggleItalics(_ sender: Any?) {
        // TODO: Implement on macOS
        fatalError()
    }
    
    @objc func toggleBoldface(_ sender: Any?) {
        // TODO: Implement on macOS
        fatalError()
    }
    
    override func deleteBackward(_ sender: Any?) {
        deleteBackward()
    }
    
}

#endif
