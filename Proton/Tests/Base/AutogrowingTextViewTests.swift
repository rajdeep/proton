//
//  AutogrowingTextViewUnitTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest

@testable import Proton

class AutogrowingTextViewTests: XCTestCase {
    func testNotifiesDelegateOfBoundsChange() {
        let boundsObserver = MockBoundsObserver()
        let viewController = SnapshotTestViewController()
        let textView = AutogrowingTextView(frame: .zero, textContainer: nil, allowsScrollingMagic: false)

        let boundsChangeExpectation = expectation(description: #function)
        boundsChangeExpectation.expectedFulfillmentCount = 2

        boundsObserver.onBoundsChanged = { _ in
            boundsChangeExpectation.fulfill()
        }

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.boundsObserver = boundsObserver
        textView.text = "Sample with single line text"

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalToConstant: 80),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])

        viewController.render()
        textView.text = "Sample with single line text Sample with single line text Sample with single line text"

        viewController.render()

        waitForExpectations(timeout: 1.0)
    }
}
