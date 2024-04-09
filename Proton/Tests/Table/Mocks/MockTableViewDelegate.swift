//
//  MockTableViewDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 9/4/2024.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
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
import Proton

class MockTableViewDelegate: TableViewDelegate {
    var containerScrollView: UIScrollView?w
    var viewport: CGRect?

    var onDidReceiveFocus: ((_ tableView: TableView, _ range: NSRange, _ cell: TableCell) -> Void)?
    var onDidLoseFocus: ((_ tableView: TableView, _ range: NSRange, _ cell: TableCell) -> Void)?
    var onDidTapAtLocation: ((_ tableView: TableView, _ location: CGPoint, _ characterRange: NSRange?, _ cell: TableCell) -> Void)?
    var onDidChangeSelection: ((_ tableView: TableView, _ range: NSRange, _ attributes: [NSAttributedString.Key : Any], _ contentType: EditorContent.Name, _ cell: TableCell) -> Void)?
    var onDidChangeBounds: ((_ tableView: TableView, _ bounds: CGRect, _ cell: TableCell) -> Void)?
    var onDidSelectCells: ((_ tableView: TableView, _ cells: [TableCell]) -> Void)?
    var onDidUnselectCells: ((_ tableView: TableView, _ cells: [TableCell]) -> Void)?
    var onDidLayoutCell: ((_ tableView: TableView, _ cell: TableCell) -> Void)?

    func tableView(_ tableView: TableView, didReceiveFocusAt range: NSRange, in cell: TableCell) {
        onDidReceiveFocus?(tableView, range, cell)
    }

    func tableView(_ tableView: TableView, didLoseFocusFrom range: NSRange, in cell: TableCell) {
        onDidLoseFocus?(tableView, range, cell)
    }

    func tableView(_ tableView: TableView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: TableCell) {
        onDidTapAtLocation?(tableView, location, characterRange, cell)
    }

    func tableView(_ tableView: TableView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: TableCell) {
        onDidChangeSelection?(tableView, range, attributes, contentType, cell)
    }

    func tableView(_ tableView: TableView, didChangeBounds bounds: CGRect, in cell: TableCell) {
        onDidChangeBounds?(tableView, bounds, cell)
    }

    func tableView(_ tableView: TableView, didSelectCells cells: [TableCell]) {
        onDidSelectCells?(tableView, cells)
    }

    func tableView(_ tableView: TableView, didUnselectCells cells: [TableCell]) {
        onDidUnselectCells?(tableView, cells)
    }

    func tableView(_ tableView: TableView, didReceiveKey key: EditorKey, at range: NSRange, in cell: TableCell) {
        //TODO:
    }

    func tableView(_ tableView: TableView, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool {
        //TODO:
        return true
    }

    func tableView(_ tableView: Proton.TableView, didLayoutCell cell: Proton.TableCell) {
        onDidLayoutCell?(tableView, cell)
    }
}
