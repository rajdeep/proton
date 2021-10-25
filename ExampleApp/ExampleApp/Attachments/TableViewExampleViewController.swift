//
//  TableViewExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 30/9/21.
//  Copyright © 2021 Rajdeep Kwatra. All rights reserved.
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

class TableViewExampleViewController: ExamplesBaseViewController {
    let numberOfRowsTextField = UITextField()
    let tableView = UITableView()
    private static let cellIdentifier = "cellIdentifier"

    var data = [NSAttributedString]()
    var counter = 1

    var numberOfRows: Int {
        let width = Int(numberOfRowsTextField.text ?? "0") ?? 100
        return width
    }

    override func setup() {
        super.setup()

        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(EditorCell.self, forCellReuseIdentifier: Self.cellIdentifier)

        view.addSubview(tableView)

        tableView.layer.borderColor = UIColor.systemBlue.cgColor
        tableView.layer.borderWidth = 1.0
        tableView.autoresizingMask = [.flexibleHeight]
        tableView.rowHeight = UITableView.automaticDimension

        let button = UIButton(type: .system)
        button.setTitle("Generate rows", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(insertAttachment(sender:)), for: .touchUpInside)

        view.addSubview(button)

        numberOfRowsTextField.translatesAutoresizingMaskIntoConstraints = false
        numberOfRowsTextField.placeholder = "Rows"
        numberOfRowsTextField.borderStyle = .roundedRect

        view.addSubview(numberOfRowsTextField)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: numberOfRowsTextField.trailingAnchor, constant: 10),

            numberOfRowsTextField.topAnchor.constraint(equalTo: button.topAnchor),
            numberOfRowsTextField.widthAnchor.constraint(equalToConstant: 60),
            numberOfRowsTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            tableView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400)
        ])
    }

    @objc
    func insertAttachment(sender: UIButton) {
        data.removeAll()
        counter = 1
        for i in 1...Int(numberOfRows) {
            data.append(createText(row: i))
        }
        tableView.reloadData()
        numberOfRowsTextField.resignFirstResponder()
    }

    private func createText(row: Int) -> NSAttributedString {
        let text = NSMutableAttributedString()
        let random = Int.random(in: 3..<10)
        for i in 0..<Int(random) {
            let attachment = PanelAttachment(frame: .zero)
            attachment.selectBeforeDelete = true
            attachment.view.editor.isEditable = false
            attachment.view.editor.attributedText = NSAttributedString(string: "Overall: \(counter) Row: \(row) Panel: \(i)")
            text.append(NSAttributedString(attachment: attachment))
            counter += 1
        }
        return text
    }
}

extension TableViewExampleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        if let cell = cell as? EditorCell {
            cell.editor.attributedText = data[indexPath.row]
            cell.layoutIfNeeded()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
}

class EditorCell: UITableViewCell {
    let editor = EditorView()

    convenience init() {
        self.init(frame: .zero)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.maxHeight = .infinite
        editor.isEditable = false

        contentView.addSubview(editor)

        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            editor.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            editor.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}
