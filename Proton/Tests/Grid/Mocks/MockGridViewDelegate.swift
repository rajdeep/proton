//
//  MockGridViewDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 9/6/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
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
import Proton

class MockGridViewDelegate: GridViewDelegate {
    var onDidReceiveFocus: ((_ gridView: GridView, _ range: NSRange, _ cell: GridCell) -> Void)?
    var onDidLoseFocus: ((_ gridView: GridView, _ range: NSRange, _ cell: GridCell) -> Void)?
    var onDidTapAtLocation: ((_ gridView: GridView, _ location: CGPoint, _ characterRange: NSRange?, _ cell: GridCell) -> Void)?
    var onDidChangeSelection: ((_ gridView: GridView, _ range: NSRange, _ attributes: [NSAttributedString.Key : Any], _ contentType: EditorContent.Name, _ cell: GridCell) -> Void)?
    var onDidChangeBounds: ((_ gridView: GridView, _ bounds: CGRect, _ cell: GridCell) -> Void)?
    var onDidSelectCells: ((_ gridView: GridView, _ cells: [GridCell]) -> Void)?
    var onDidUnselectCells: ((_ gridView: GridView, _ cells: [GridCell]) -> Void)?

    func gridView(_ gridView: GridView, didReceiveFocusAt range: NSRange, in cell: GridCell) {
        onDidReceiveFocus?(gridView, range, cell)
    }

    func gridView(_ gridView: GridView, didLoseFocusFrom range: NSRange, in cell: GridCell) {
        onDidLoseFocus?(gridView, range, cell)
    }

    func gridView(_ gridView: GridView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: GridCell) {
        onDidTapAtLocation?(gridView, location, characterRange, cell)
    }

    func gridView(_ gridView: GridView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: GridCell) {
        onDidChangeSelection?(gridView, range, attributes, contentType, cell)
    }

    func gridView(_ gridView: GridView, didChangeBounds bounds: CGRect, in cell: GridCell) {
        onDidChangeBounds?(gridView, bounds, cell)
    }

    func gridView(_ gridView: GridView, didSelectCells cells: [GridCell]) {
        onDidSelectCells?(gridView, cells)
    }

    func gridView(_ gridView: GridView, didUnselectCells cells: [GridCell]) {
        onDidUnselectCells?(gridView, cells)
    }

    func gridView(_ gridView: GridView, didReceiveKey key: EditorKey, at range: NSRange, in cell: GridCell) {
        //TODO:
    }
}
