//
//  MockEditorCommand.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 23/2/20.
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

import Proton

class MockEditorCommand: EditorCommand {
    var onCanExecute: (EditorView) -> Bool
    var onExecute: (EditorView) -> Void
    let name: CommandName

    init(name: String = "_MockEditorCommand", onCanExecute: @escaping ((EditorView) -> Bool) = { _ in true },
         onExecute: @escaping ((EditorView) -> Void)) {
        self.name = CommandName(name)
        self.onCanExecute = onCanExecute
        self.onExecute = onExecute
    }

    func canExecute(on editor: EditorView) -> Bool {
        return onCanExecute(editor)
    }

    func execute(on editor: EditorView) {
        onExecute(editor)
    }
}
