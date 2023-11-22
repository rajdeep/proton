//
//  ListDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 5/6/20.
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

/// Marker for the list item
public enum ListLineMarker {
    case string(NSAttributedString)
    case image(UIImage, size: CGSize)
}

/// Describes an object capable of providing style and formatting information for rendering lists in `EditorView`.
public protocol EditorListFormattingProvider: AnyObject {

    /// Line formatting to be used for a list item.
    var listLineFormatting: LineFormatting { get }

    /// Returns the marker to be drawn for list item (bullet/number etc.) for given parameters.
    /// - Parameters:
    ///   - editor: Editor in which list marker is being drawn.
    ///   - index: Index of list item in the given list.
    ///   - level: Indentation level of the list.
    ///   - previousLevel: Previous indentation level. Using this, it can be determined if the list is being indented, outdented or is at same level.
    ///   - attributeValue: Value of list item attribute for given index. Nil if there is no content set in list item yet.
    /// - Returns: Marker to be drawn for the given list item.
    /// - Note: This function is called multiple times for same index level based on TextKit layout cycles. It is advisable to cache
    /// the values if calculation/drawing is performance intensive.
    func listLineMarkerFor(editor: EditorView, index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker

    /// Invoked before the indentation level is changed. This may be used to change the list attribute value, if needed.
    /// - Parameters:
    ///   - editor: Editor in which indentation is going to be changed.
    ///   - range: Range of affected text
    ///   - currentLevel: Current nested level of list, with first level being 1.
    ///   - indentMode: Indentation action to be performed
    ///   - latestAttributeValueAtProposedLevel: List item attribute value immediately preceding the current item at the new level that the current item will be indented to.
    ///   The value is`nil` if preceding item does not exist at the new level.
    func willChangeListIndentation(editor: EditorView, range: NSRange, currentLevel: Int, indentMode: Indentation, latestAttributeValueAtProposedLevel: Any?)
}

public extension EditorListFormattingProvider {
    func willChangeListIndentation(editor: EditorView, range: NSRange, currentLevel: Int, indentMode: Indentation, latestAttributeValueAtProposedLevel: Any?) { }
}
