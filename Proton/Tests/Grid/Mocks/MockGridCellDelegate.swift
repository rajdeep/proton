//
//  MockGridCellDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/12/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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
@testable import Proton

class MockGridCellDelegate: GridCellDelegate {
    var onDidChangeBounds: ((GridCell, CGRect) -> Void)?
    var onDidReceiveFocus: ((GridCell, NSRange) -> Void)?
    var onDidLoseFocus: ((GridCell, NSRange) -> Void)?
    var onDidTapAtLocation: ((GridCell, CGPoint, NSRange?) -> Void)?
    var onDidChangeSelection: ((GridCell, NSRange, [NSAttributedString.Key : Any], EditorContent.Name) -> Void)?
    var onDidReceiveKey: ((GridCell, EditorKey, NSRange) -> Void)?
    var onDidChangeSelected: ((GridCell, Bool) -> Void)?
    var onDidChangeBackgroundColor: ((GridCell, UIColor?, UIColor?) -> Void)?


    func cell(_ cell: GridCell, didChangeBounds bounds: CGRect) {
        onDidChangeBounds?(cell, bounds)
    }

    func cell(_ cell: GridCell, didReceiveFocusAt range: NSRange) {
        onDidReceiveFocus?(cell, range)
    }

    func cell(_ cell: GridCell, didLoseFocusFrom range: NSRange) {
        onDidLoseFocus?(cell, range)
    }

    func cell(_ cell: GridCell, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        onDidTapAtLocation?(cell, location, characterRange)
    }

    func cell(_ cell: GridCell, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        onDidChangeSelection?(cell, range, attributes, contentType)
    }

    func cell(_ cell: GridCell, didReceiveKey key: EditorKey, at range: NSRange) {
        onDidReceiveKey?(cell, key, range)
    }

    func cell(_ cell: GridCell, didChangeSelected isSelected: Bool) {
        onDidChangeSelected?(cell, isSelected)
    }

    func cell(_ cell: GridCell, didChangeBackgroundColor color: UIColor?, oldColor: UIColor?) {
        onDidChangeBackgroundColor?(cell, color, oldColor)
    }
}
