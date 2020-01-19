//
//  AutogrowingTextViewViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 2/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class AutogrowingEditorViewExampleViewController: ExamplesBaseViewController {

    let editor = EditorView()

    override func setup() {
        super.setup()
        
        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.blue.cgColor
        editor.layer.borderWidth = 1.0
        
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            editor.heightAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])

        editor.placeholderText = NSAttributedString(string: "This is a placeholder text that flows into the next line",
                                                    attributes: [
                                                        NSAttributedString.Key.font : editor.font ?? UIFont.systemFont(ofSize: 17),
                                                        NSAttributedString.Key.foregroundColor: UIColor.lightGray
        ])
    }
}
