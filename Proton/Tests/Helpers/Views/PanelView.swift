//
//  PanelView.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

class PanelView: UIView, BlockContent, EditorContentView {
    let editor: EditorView
    let iconView = UIImageView()

    var name: EditorContent.Name {
        return EditorContent.Name("panel")
    }

    override init(frame: CGRect) {
        self.editor = EditorView(frame: frame)
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var backgroundColor: UIColor? {
        didSet {
            editor.backgroundColor = backgroundColor
        }
    }

    private func setup() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.paragraphStyle.firstLineHeadIndent = 0

        addSubview(iconView)
        addSubview(editor)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),

            editor.topAnchor.constraint(
                equalTo: iconView.topAnchor, constant: -editor.textContainerInset.top),
            editor.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            editor.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            editor.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])

        iconView.layer.borderColor = UIColor.black.cgColor
        iconView.layer.borderWidth = 1.0
        iconView.backgroundColor = .white

        layer.cornerRadius = 5.0
        clipsToBounds = true
    }
}
