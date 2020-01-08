//
//  WidthRangeAttachmentExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class WidthRangeAttachmentExampleViewController: ExamplesBaseViewController {
    let editor = EditorView()
    let minWidthTextField = UITextField()
    let maxWidthTextField = UITextField()

    var minWidth: CGFloat {
        let width = CGFloat(exactly: NumberFormatter().number(from: (minWidthTextField.text ?? "")) ?? 40) ?? 40
        return width
    }

    var maxWidth: CGFloat {
        let width = CGFloat(exactly: NumberFormatter().number(from: (maxWidthTextField.text ?? "")) ?? 120) ?? 120
        return width
    }

    override func setup() {
        super.setup()

        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.blue.cgColor
        editor.layer.borderWidth = 1.0

        let button = UIButton(type: .system)
        button.setTitle("Insert attachment", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(insertAttachment(sender:)), for: .touchUpInside)

        view.addSubview(button)

        minWidthTextField.translatesAutoresizingMaskIntoConstraints = false
        minWidthTextField.placeholder = "Min"
        minWidthTextField.borderStyle = .roundedRect

        view.addSubview(minWidthTextField)

        maxWidthTextField.translatesAutoresizingMaskIntoConstraints = false
        maxWidthTextField.placeholder = "Max"
        maxWidthTextField.borderStyle = .roundedRect

        view.addSubview(maxWidthTextField)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: maxWidthTextField.trailingAnchor, constant: 10),

            minWidthTextField.topAnchor.constraint(equalTo: button.topAnchor),
            minWidthTextField.widthAnchor.constraint(equalToConstant: 60),
            minWidthTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            maxWidthTextField.topAnchor.constraint(equalTo: button.topAnchor),
            maxWidthTextField.widthAnchor.constraint(equalToConstant: 60),
            maxWidthTextField.leadingAnchor.constraint(equalTo: minWidthTextField.trailingAnchor, constant: 10),

            editor.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }

    @objc
    func insertAttachment(sender: UIButton) {
        let textField = AutogrowingTextField()
        textField.backgroundColor = .cyan
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 4.0
        textField.layer.borderColor = UIColor.black.cgColor
        textField.font = editor.font

        let attachment = Attachment(textField, size: .range(minWidth: minWidth, maxWidth: maxWidth))
        textField.boundsObserver = attachment
        attachment.offsetProvider = self
        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
    }
}

extension WidthRangeAttachmentExampleViewController: AttachmentOffsetProviding {
    func offset(for attachment: Attachment, in textContainer: NSTextContainer, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGPoint {
        return CGPoint(x: 0, y: -2)
    }
}

class InlineEditorView: EditorView, InlineAttachment {
    public var name: EditorContent.Name {
        return EditorContent.Name("Editor")
    }
}
