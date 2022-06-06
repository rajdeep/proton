//
//  GridViewAttachment.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/6/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
//

import Foundation

extension EditorContent.Name {
    static let grid = EditorContent.Name("grid")
}

public class GridViewAttachment: Attachment {
    var view: GridView

    public init(config: GridConfiguration) {
        view = GridView(config: config)
        super.init(view, size: .fullWidth)
        view.boundsObserver = self
    }
}

extension GridView: BlockContent {
    open var name: EditorContent.Name {
        return .grid
    }
}
