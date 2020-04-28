//
//  MenuDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 28/4/20.
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

/// Describes an object responsible for providing the actions shown in the menu on
/// right-click/tap. The object must conform to `NSObjectProtocol`.
public protocol MenuDelegate: NSObjectProtocol {

    /// Returns all the supported default(inbuilt) actions for the editor/renderer e.g. select, select all, copy, paste  etc.
    /// Value of `true` must be returned for all the actions that are supported.
    ///
    /// - Note:
    /// This function only expects `true` to be returned for the supported actions. Whether the action is shown in the menu or not,
    /// is handled automatically based on the context. For e.g. even if `true` is returned for selector `select(:)`, it  will not be
    /// shown if the editor/renderer is empty as there is nothing to select.
    ///
    /// Any custom menu item that needs to be displayed must be added to `UIMenuController.shared.menuItems`. Also, `canPerformAction(action:sender)` should
    /// be overridden to return true/false based on the context. These items will be shown in the menu in addition to default actions supported
    /// by this function.
    /// - Parameters:
    ///   - action: Name of the action
    ///   - sender: sender  of the action
    func canPerformDefaultAction(_ action: Selector, withSender sender: Any?) -> Bool
}
