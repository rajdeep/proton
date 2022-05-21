//
//  ExpandableView.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 21/5/2022.
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

import Proton

extension EditorContent.Name {
    static let expandable = EditorContent.Name("expandable")
}

class ExpandableView: UIView, BlockContent, EditorContentView {
    let container = UIView()
    let editor: EditorView
    let button = UIButton()
    let textField = UITextField()

    weak var delegate: PanelViewDelegate?

    private var heightConstraint: NSLayoutConstraint!

    var name: EditorContent.Name {
        return .panel
    }

    override init(frame: CGRect) {
        self.editor = EditorView(frame: frame)
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var textColor: UIColor {
        get { editor.textColor }
        set { editor.textColor = newValue }
    }

    override var backgroundColor: UIColor? {
        get { container.backgroundColor }
        set {
            container.backgroundColor = newValue
            editor.backgroundColor = newValue
        }
    }

    private func setup() {
        container.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        editor.paragraphStyle.firstLineHeadIndent = 0

        container.layer.borderWidth = 1.0
        container.layer.cornerRadius = 4.0
        container.layer.borderColor = UIColor.systemGray3.cgColor
        container.backgroundColor = UIColor.systemBackground

        addSubview(container)
        container.addSubview(editor)
        container.addSubview(button)
        container.addSubview(textField)

        heightConstraint = container.heightAnchor.constraint(equalToConstant: 45)
        heightConstraint.isActive = false

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),

            button.heightAnchor.constraint(equalToConstant: 30),
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),

            textField.topAnchor.constraint(equalTo: container.topAnchor, constant: 5),
            textField.leadingAnchor.constraint(equalTo: button.trailingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5),

            editor.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 10),
            editor.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 5),
            editor.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5),
            editor.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        setButtonImage(isExpanded: true)
        button.addTarget(self, action: #selector(buttonClick(sender:)), for: .touchUpInside)
        button.tintColor = UIColor.systemGray3

        textField.placeholder = "Add title here"
        textField.textColor = UIColor.systemGray

        container.layer.cornerRadius = 5.0
        container.clipsToBounds = true
    }

    @objc
    private func buttonClick(sender: UIButton) {
        heightConstraint.isActive = !heightConstraint.isActive
        setButtonImage(isExpanded: !heightConstraint.isActive)
        self.layoutIfNeeded()
    }

    private func setButtonImage(isExpanded: Bool) {
        if isExpanded {
            button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        } else {
            button.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        }
    }
}

extension ExpandableView {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        container.layer.borderColor = UIColor.systemGray.cgColor
        button.layer.borderColor = UIColor.systemGray.cgColor
    }
}
