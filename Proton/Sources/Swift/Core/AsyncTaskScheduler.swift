//
//  AsyncTaskScheduler.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 11/9/2023.
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

class AsyncTaskScheduler {
    typealias VoidTask = () -> Void
    private var executing = false

    private var tasks = SynchronizedArray<(id: String, task: VoidTask)>()
    private var scheduled = SynchronizedArray<String>()

    var pending = false {
        didSet {
            guard pending == false else { return }
            executeNext()
        }
    }

    func clear() {
        tasks.removeAll()
    }

    func enqueue(id: String, task: @escaping VoidTask) {
        guard tasks.contains(where: { $0.id == id }) == false else { return }
        self.tasks.append((id, task))
    }

    func dequeue(_ completion: @escaping (String, VoidTask?) -> Void)  {
        guard let task = self.tasks.remove(at: 0) else {
            completion("", nil)
            return
        }
        completion(task.id, task.task)
    }

    func executeNext() {
        guard !pending else { return }
        dequeue { id, task in
            if let task {
                self.pending = true
                // A delay is required so that tracking mode may be intercepted.
                // Intercepting tracking allows handling of user interactions on UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) { [weak self] in
                    guard let self else { return }
                    if RunLoop.current.currentMode != .tracking {
                        task()
                        self.pending = false
                    } else {
                        self.pending = false
                        self.tasks.insert((id: id, task: task), at: 0)
                        self.executeNext()
                    }
                }
            }
        }
    }
}
