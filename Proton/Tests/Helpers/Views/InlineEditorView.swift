//
//  InlineEditorView.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

class InlineEditorView: EditorView, InlineContent {
    public var name: EditorContent.Name {
        return EditorContent.Name("Editor")
    }
}
