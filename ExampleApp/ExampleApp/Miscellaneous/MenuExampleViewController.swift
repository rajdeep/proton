//
//  MenuExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/4/20.
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

class MenuExampleViewController: ExamplesBaseViewController {

    let commandExecutor = EditorCommandExecutor()

    override func setup() {
        super.setup()

        let editor = TestEditor()
        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.systemBlue.cgColor
        editor.layer.borderWidth = 1.0

        editor.delegate = self

        let button = UIButton(type: .system)
        button.setTitle("Insert panel", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(insertPanel(sender:)), for: .touchUpInside)

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            editor.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(resetMenu))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc
    func insertPanel(sender: UIButton) {
        UIMenuController.shared.menuItems = nil
        commandExecutor.execute(PanelCommand())
    }

    @objc
    func resetMenu() {
        var title = "Test"
        #if targetEnvironment(macCatalyst)
            title = "\(title)..."
        #endif

        // Add custom menu items to UIMenuController. This is other than default items of cut/copy/paste etc.
        let testMenu = UIMenuItem(title: title, action: #selector(showSubMenu))
        UIMenuController.shared.menuItems = [
            testMenu
        ]
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Add any custom  menu item selectors here
        return (action == #selector(a) ||
            action == #selector(b) ||
            action == #selector(showSubMenu))
    }
}

extension MenuExampleViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MenuExampleViewController: EditorViewDelegate {
    func editor(_ editor: EditorView, didChangeTextAt range: NSRange) {
        UIMenuController.shared.menuItems = nil
        UIMenuController.shared.hideMenu()
    }
}

extension MenuExampleViewController {
    @objc func a() {
        print("A")
        resetMenu()
    }

    @objc func b() {
        print("B")
        resetMenu()
    }

    @objc func showSubMenu() {
        guard let editor = EditorViewContext.shared.activeEditorView else { return }
        let menu = UIMenuController.shared
        let frame = editor.caretRect(for: editor.selectedRange.location)
        menu.menuItems = [
            UIMenuItem(title: "A", action: #selector(a)),
            UIMenuItem(title: "B", action: #selector(b))
        ]

        // Despite the warning, it seems that you need to explicitly set menu to visible on iOS 13
        menu.isMenuVisible = true
        menu.showMenu(from: editor, rect: frame)
    }
}

class TestEditor: EditorView {
    override func copy(_ sender: Any?) {
        print("Custom copy")
    }

    override func paste(_ sender: Any?) {
        print("Custom Paste")
    }

    override func cut(_ sender: Any?) {
        print("Custom Cut")
    }

    override func canPerformMenuAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Example to disable selector. Copy only available when text length > 5 and also allowed by the UITextView's current state
        // e.g. even if text length is greater than 5, copy will be disabled if no text is selected.
        if action == #selector(copy(_:)) {
            return attributedText.length > 5
        }

        // to apply default behaviour, return true
        return true

    }
}
