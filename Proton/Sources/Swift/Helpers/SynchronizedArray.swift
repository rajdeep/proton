//
//  ThreadSafeArray.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 13/9/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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

final class SynchronizedArray<Element>: Sequence {

    private var array: [Element]
    private let queue: DispatchQueue

    var count: Int {
        return queue.sync { self.array.count }
    }

    var isEmpty: Bool {
        return queue.sync { self.array.isEmpty }
    }

    var first: Element? {
        return queue.sync { self.array.first }
    }

    var last: Element? {
        return queue.sync { self.array.last }
    }

    init(array: [Element] = [], qos: DispatchQoS = .userInteractive) {
        self.array = array
        self.queue = DispatchQueue(label: "com.proton.synchronizedArray", qos: qos)
    }

    @discardableResult
    func remove(at index: Int) -> Element? {
        return queue.sync {
            guard self.array.isEmpty == false else {
                return nil
            }
            return self.array.remove(at: index)
        }
    }

    func append(_ newElement: Element) {
        queue.sync { self.array.append(newElement) }
    }

    func insert(_ newElement: Element, at index: Int) {
        queue.sync { self.array.insert(newElement, at: index) }
    }

    func makeIterator() -> Array<Element>.Iterator {
        return queue.sync { self.array.makeIterator() }
    }

    func asArray() -> [Element] {
        return queue.sync { self.array }
    }
}
