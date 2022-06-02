//
//  ListOutdentCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 2/6/2022.
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
import UIKit

/// Command that can be used to toggle list indentation of selected range of text.
public class ListOutdentCommand: EditorCommand {
    public init() { }

    /// Name of the command
    public var name: CommandName {
        return CommandName("listOutdentCommand")
    }

    /// Outdents a list item if it supports reversing indentation. When applied on an item at first level, it will remove item from the list.
    /// If the command is executed on a text without `NSAttributedString.Key.listItem` attribute, the command is a no-op
    public func execute(on editor: EditorView) {
        let listTextProcessor = ListTextProcessor()
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [.shift], range: editor.selectedRange)
    }
}
