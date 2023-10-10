//
//  RichTextViewDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 7/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit

public enum EditorKey {
    case enter
    case backspace
    case tab
    case left
    case right
    case up
    case down

    init?(_ string: String) {
        switch string {
        case "\t":
            self = .tab
        case "\n", "\r":
            self = .enter
        case UIKeyCommand.inputUpArrow:
            self = .up
        case UIKeyCommand.inputDownArrow:
            self = .down
        case UIKeyCommand.inputLeftArrow:
            self = .left
        case UIKeyCommand.inputRightArrow:
            self = .right
        default:
            return nil
        }
    }
}

protocol RichTextViewDelegate: AnyObject {
    func richTextView(_ richTextView: RichTextView, didChangeSelection range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name)
    func richTextView(_ richTextView: RichTextView, shouldHandle key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange, handled: inout Bool)
    func richTextView(_ richTextView: RichTextView, didReceive key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange)
    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange)
    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange)
    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool)
    func richTextView(_ richTextView: RichTextView, didChangeTextAtRange range: NSRange)
    func richTextView(_ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?)
    func richTextView(_ richTextView: RichTextView, selectedRangeChangedFrom oldRange: NSRange?, to newRange: NSRange?)
}

protocol RichTextViewListDelegate: AnyObject {
    var listLineFormatting: LineFormatting { get }
    func richTextView(_ richTextView: RichTextView, listMarkerForItemAt index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker
}
