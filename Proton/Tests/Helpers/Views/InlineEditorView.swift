//
//  InlineEditorView.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class InlineEditorView: EditorView, InlineContent {
    public var name: EditorContent.Name {
        return EditorContent.Name("Editor")
    }
}
