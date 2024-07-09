//
//  ListParser.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 29/10/20.
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
import ProtonCore

/// Represents an item in the list. This structure may be used to create `NSAttributedString` from items in an array of `ListItem`. Alternatively, `NSAttributedString` may also be parsed to get an array of `ListItem`s.
public struct ListItem {

    /// Text of the list item. All attributes are preserved as is.
    /// - Note: If the text contains a newline (`\n`), it is preserved as a newline in text by applying `.skipNextListMarker` attribute.
    public let text: NSAttributedString

    /// Level of the list item. This is used with indent to get `paragraphStyle` to be applied with appropriate indentation of the list items.
    public let level: Int

    /// Attribute value of the list item.
    public let attributeValue: Any

    /// Creates a `ListItem`
    /// - Parameters:
    ///   - text: Attributed value for text in `ListItem`
    ///   - level: Indentation level of `ListItem`.
    ///   - attributeValue: Attribute value to be applied to entire text range of `ListItem`
    public init(text: NSAttributedString, level: Int, attributeValue: Any) {
        self.text = text
        self.level = level
        self.attributeValue = attributeValue
    }
}

public class ListItemNode {
    public let item: ListItem
    public internal(set) var children: [ListItemNode]

    init(item: ListItem, children: [ListItemNode]) {
        self.item = item
        self.children = children
    }
}

/// Provides helper function to convert between `NSAttributedString` and `[ListItem]`
public struct ListParser {

    /// Parses an array of list items into an `NSAttributedString` representation. `NewLines` are automatically added between each list item in the attributed string representation.
    /// - Parameters:
    ///   - list: List items to convert
    ///   - indent: Indentation to be used. This determines the paragraph indentation for layout.
    /// - Returns: NSAttributedString representation of list items
    public static func parse(list: [ListItem], indent: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        for i in 0..<list.count {
            let item = list[i]
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.firstLineHeadIndent = CGFloat(item.level) * indent
            paraStyle.headIndent = paraStyle.firstLineHeadIndent
            let listText = NSMutableAttributedString(attributedString: item.text)
            listText.addAttribute(.listItem, value: item.attributeValue, range: listText.fullRange)
            listText.addAttribute(.paragraphStyle, value: paraStyle, range: listText.fullRange)
            let newLineRanges = listText.rangesOf(characterSet: .newlines)
            for newLineRange in newLineRanges {
                listText.addAttributes([
                    .blockContentType:EditorContentName.newline(),
                    .skipNextListMarker: 1
                ], range: newLineRange)
            }

            if i < list.count - 1 {
                listText.append(NSAttributedString(string: "\n",
                                                   attributes: [
                                                    NSAttributedString.Key.blockContentType:EditorContentName.newline(),
                                                    NSAttributedString.Key.listItem: item.attributeValue,
                                                    NSAttributedString.Key.paragraphStyle: paraStyle
                                                   ]))
            }
            attributedString.append(listText)
        }
        return attributedString
    }

    /// Parses NSAttributedString to list items
    /// - Parameters:
    ///   - attributedString: NSAttributedString to convert to list items.
    ///   - indent: Indentation used in list representation in attributedString. This determines the level of list item.
    /// - Returns: Array of list items with corresponding range in attributedString along with `listIndex` denoting the index of list in the complete text. All items in the same list will have same index.
    ///`listIndex` may be used to distinguish items of one list from another.
    /// - Note: If NSAttributedString passed into the function is non continuous i.e. contains multiple lists, the array will contain items from all the list with the range corresponding to range of text in original attributed string.
    public static func parse(attributedString: NSAttributedString, indent: CGFloat = 25) -> [(listIndex: Int, range: NSRange, listItem: ListItem)] {
        var items = [(listIndex: Int, range: NSRange, listItem: ListItem)]()
        var counter = 1
        attributedString.enumerateAttribute(.listItem, in: attributedString.fullRange, options: []) { (value, range, _) in
            if value != nil {
                let listItems = parseList(in: attributedString.attributedSubstring(from: range), rangeInOriginalString: range, indent: indent, attributeValue: value)
                items.append(contentsOf: listItems.map {(listIndex: counter, range: $0.range, listItem: $0.listItem)})
                counter += 1
            }
        }
        return items
    }

    /// Parses NSAttributedString to list items
    /// - Parameters:
    ///   - attributedString: NSAttributedString to convert to list items.
    ///   - indent: Indentation used in list representation in attributedString. This determines the level of list item.
    /// - Returns: Array of list item nodes with hierarchical representation of list
    /// - Note: If NSAttributedString passed into the function is non continuous i.e. contains multiple lists, the array will contain items from all the list with the range corresponding to range of text in original attributed string.
    public static func parseListHierarchy(attributedString: NSAttributedString, indent: CGFloat = 25) -> [ListItemNode] {
        let listItems = parse(attributedString: attributedString, indent: indent).map { $0.listItem }
        return createListItemNodes(from: listItems)
    }

    /// Creates hierarchical representation of `ListItem` from the provided collection based on levels of each of the items
    /// - Parameter listItems: ListItems to convert
    /// - Returns: Collection of `ListItemNode` with each node having children nodes based on level of individual list items.
    public static func createListItemNodes(from listItems: [ListItem]) -> [ListItemNode] {
        var result = [ListItemNode]()
        var stack: [(node: ListItemNode, level: Int)] = []

        for item in listItems {
            let newNode = ListItemNode(item: item, children: [])

            // Pop from the stack until the current item's parent is found
            while let last = stack.last, last.level >= item.level {
                stack.removeLast()
            }

            if stack.last != nil {
                // If there's a parent, add this node to its children
                stack[stack.count - 1].node.children.append(newNode)
            } else {
                // If there's no parent, this is a root node
                result.append(newNode)
            }

            // Push the current node onto the stack
            stack.append((newNode, item.level))
        }

        // Since we've been directly modifying the nodes in the stack, the `result` array now contains the fully constructed tree
        return result
    }

    private static func parseList(in attributedString: NSAttributedString, rangeInOriginalString: NSRange, indent: CGFloat, attributeValue: Any?) -> [(range: NSRange, listItem: ListItem)] {
        var items = [(range: NSRange, listItem: ListItem)]()

        attributedString.enumerateAttribute(.paragraphStyle, in: attributedString.fullRange, options: []) { paraAttribute, paraRange, _ in
            if let paraStyle = paraAttribute as? NSParagraphStyle {
                let level = Int(paraStyle.headIndent/indent)
                let text = attributedString.attributedSubstring(from: paraRange)
                var lines = listLinesFrom(text: text)//text.string.components(separatedBy: .newlines)

                if lines.last?.text.string.isEmpty ?? false {
                    lines.remove(at: lines.count - 1)
                }

                for i in 0..<lines.count {
                    let line = lines[i]
                    let itemRange = line.range
                    let newlineRange = NSRange(location: max(itemRange.location - 1, 0), length: 1)
                    if newlineRange.endLocation < text.length,
                       text.attributeValue(for: .skipNextListMarker, at: newlineRange.location) != nil,
                       var lastItem = items.last {
                        lastItem.range = NSRange(location: lastItem.range.location, length: itemRange.endLocation)
                        lastItem.listItem = ListItem(text: text.attributedSubstring(from: lastItem.range), level: level, attributeValue: attributeValue as Any)
                        items.remove(at: items.count - 1)
                        items.append((range: lastItem.range.shiftedBy(paraRange.location + rangeInOriginalString.location), listItem: lastItem.listItem))
                    } else {
                        let listLine = text.attributedSubstring(from: itemRange)
                        let item = ListItem(text: listLine, level: level, attributeValue: attributeValue as Any)
                        items.append((itemRange.shiftedBy(paraRange.location + rangeInOriginalString.location), item))
                    }
                }
            }
        }
        return items
    }

    private static func listLinesFrom(text: NSAttributedString) -> [(text: NSAttributedString, range: NSRange)] {
        var listItems = [(text: NSAttributedString, range: NSRange)]()

        let newlineRanges = text.rangesOf(characterSet: .newlines)
        var startIndex = 0

        for newlineRange in newlineRanges {
            let isNewlineSkipMarker = text.attribute(.skipNextListMarker, at: newlineRange.location, effectiveRange: nil) != nil

            if isNewlineSkipMarker {
                continue
            }

            let range = NSRange(location: startIndex, length: newlineRange.location - startIndex)
            let itemText = text.attributedSubstring(from: range)
            listItems.append((text: itemText, range: range))
            startIndex = newlineRange.endLocation
        }


        let range = NSRange(location: startIndex, length: text.length - startIndex)
        let itemText = text.attributedSubstring(from: range)
        listItems.append((text: itemText, range: range))
        return listItems
    }
}
