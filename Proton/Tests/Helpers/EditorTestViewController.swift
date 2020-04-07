//
//  EditorTestViewController.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/1/20.
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

class EditorTestViewController: SnapshotTestViewController {
    let editor: EditorView
    let height: CGFloat?

    init(height: CGFloat? = nil) {
        editor = EditorView(frame: .zero)
        self.height = height
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
            editor.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor)
        ])

        guard let height = self.height else { return }

        NSLayoutConstraint.activate([
            editor.heightAnchor.constraint(equalToConstant: height),
        ])
    }
}
