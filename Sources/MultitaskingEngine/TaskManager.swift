//
//  TaskManager.swift
//  ULang
//
//  Created by Eric Russell on 2/27/25.
//

import Foundation


class TaskManager {
    private var taskQueue: [TaskExecutable] = []

    // Add a task that conforms to the TaskExecutable protocol
    func addTask(_ task: any TaskExecutable) {
        taskQueue.append(task)
    }

    // Execute all tasks in the queue
    func executeAll() async {
        for var task in taskQueue {
            await task.execute()  // Execute the task
        }
    }
}
