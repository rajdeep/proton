//
//  PanelEncoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

struct PanelEncoder: AttachmentEncoding {
    func encode(name: EditorContent.Name, view: UIView) -> JSON {
        guard let view = view as? PanelView else { return JSON() }

        var json = JSON()
        json.type = name.rawValue
        json["style"] = "info"
        let contents = view.editor.transformContents(using: JSONEncoder())
        json.contents = contents
        return json
    }
}
