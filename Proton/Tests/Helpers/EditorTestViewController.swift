//
//  EditorTestViewController.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class EditorTestViewController: SnapshotTestViewController {
    let editor: EditorView

    init() {
        editor = EditorView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.addBorder()

        view.addSubview(editor)
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: editor.trailingAnchor, constant: 20),
        ])
    }
}
