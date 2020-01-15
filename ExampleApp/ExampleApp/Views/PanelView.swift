//
//  PanelView.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

extension EditorContent.Name {
    static let panel = EditorContent.Name("panel")
}

protocol PanelViewDelegate: class {
    func panel(_ panel: PanelView, didRecieveKey key: EditorKey, at range: NSRange, handled: inout Bool)
    func panel(_ panel: PanelView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name)
}

class PanelView: UIView, BlockContent, EditorContentView {
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

    override var backgroundColor: UIColor? {
        didSet {
            editor.backgroundColor = backgroundColor
        }
    }

    private func setup() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.paragraphStyle.firstLineHeadIndent = 0
        editor.delegate = self

        self.backgroundColor = .lightGray
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 4.0
        self.layer.borderColor = UIColor.black.cgColor

        addSubview(iconView)
        addSubview(editor)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),

            editor.topAnchor.constraint(equalTo: iconView.topAnchor, constant: -editor.textContainerInset.top),
            editor.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            editor.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            editor.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])

        iconView.layer.borderColor = UIColor.black.cgColor
        iconView.layer.borderWidth = 1.0
        iconView.backgroundColor = .white

        layer.cornerRadius = 5.0
        clipsToBounds = true
    }
}

extension PanelView: EditorViewDelegate {
    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) {
        delegate?.panel(self, didRecieveKey: key, at: range, handled: &handled)
    }

    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        // Relay the changed selection command to container `EditorView`'s delegate
        // This needs to be done as an additional step as container `EditorView`'s delegate is not registered as `PanelView`'s
        // editor as the `PanelView` register's itself as the `EditorView`'s delegate
        delegate?.panel(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }
}
