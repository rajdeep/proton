//
//  PanelView.swift
//  ExampleApp
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

extension EditorContent.Name {
    static let panel = EditorContent.Name("panel")
}

protocol PanelViewDelegate: AnyObject {
    func panel(_ panel: PanelView, shouldHandle key: EditorKey, at range: NSRange, handled: inout Bool)
    func panel(_ panel: PanelView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name)
}

class PanelView: UIView, BlockContent, EditorContentView {
    let container = UIView()
    let editor: EditorView
    let iconView = UIImageView()

    weak var delegate: PanelViewDelegate?

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
        iconView.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.paragraphStyle.firstLineHeadIndent = 0
        editor.delegate = self

        backgroundColor = UIColor(red: 0.99, green: 0.97, blue: 0.89, alpha: 1.00)
        container.layer.borderWidth = 1.0
        container.layer.cornerRadius = 4.0
        container.layer.borderColor = UIColor(red: 0.99, green: 0.95, blue: 0.84, alpha: 1.00).cgColor

        addSubview(container)
        container.addSubview(iconView)
        container.addSubview(editor)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.heightAnchor.constraint(equalToConstant: 30),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),

            editor.topAnchor.constraint(equalTo: iconView.topAnchor, constant: -editor.textContainerInset.top),
            editor.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            editor.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5),
            editor.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])

        iconView.image = UIImage(systemName: "exclamationmark.triangle")
        iconView.tintColor = UIColor.orange

        container.layer.cornerRadius = 5.0
        container.clipsToBounds = true
    }
}

extension PanelView: EditorViewDelegate {
    func editor(_ editor: EditorView, shouldHandle key: EditorKey, at range: NSRange, handled: inout Bool) {
        delegate?.panel(self, shouldHandle: key, at: range, handled: &handled)
    }

    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        // Relay the changed selection command to container `EditorView`'s delegate
        // This needs to be done as an additional step as container `EditorView`'s delegate is not registered as `PanelView`'s
        // editor as the `PanelView` register's itself as the `EditorView`'s delegate
        delegate?.panel(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }
}

extension PanelView {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        container.layer.borderColor = UIColor.systemGray.cgColor
        iconView.layer.borderColor = UIColor.systemGray.cgColor
    }
}
