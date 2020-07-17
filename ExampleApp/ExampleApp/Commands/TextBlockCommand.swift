//
//  TextBlockCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 7/5/20.
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

class TextBlockCommand: EditorCommand {
    let name: CommandName = CommandName("TextBlockCommand")

    func execute(on editor: EditorView) {
        let style = BackgroundStyle(color: .green, cornerRadius: 5, shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 3))
        let attributes: [NSAttributedString.Key: Any] = [
            .textBlock: true,
            .backgroundColor: UIColor.cyan,
            .backgroundStyle: style
        ]

        editor.addAttributes(attributes, at: editor.selectedRange)
    }
}
