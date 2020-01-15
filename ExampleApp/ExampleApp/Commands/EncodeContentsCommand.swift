//
//  EncodeContentsCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class EncodeContentsCommand: EditorCommand {
    func execute(on editor: EditorView) {
        let value = editor.transformContents(using: JSONTransformer())
        let data = try! JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
        let jsonString = String.init(data: data, encoding: .utf8)!

        print(NSString(string: jsonString))
    }
}
