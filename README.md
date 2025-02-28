Multitasking Engine (MTE)

Overview

The Multitasking Engine (MTE) is a core component of the ULang project, designed to manage and execute tasks concurrently. By leveraging fiber-based multitasking and an actor-based model in Swift, the MTE facilitates efficient task execution, allowing for sequential or parallel processing with minimal resource contention.

Key Features
	•	Task Management: The MTE orchestrates tasks by splitting them into fibers, which are lightweight units of work.
	•	Cooperative Multitasking: Fibers yield control at designated points, allowing the system to execute other tasks in parallel, improving responsiveness and efficiency.
	•	Actor Model: Task management is based on actors, ensuring thread safety and concurrency control.
	•	Task Flow: Tasks can dynamically manage their flow, responding to success, failure, warnings, and events.

How It Works
	1.	Task and Fiber Model:
	•	A task consists of multiple fibers. Each fiber represents a unit of work that can be executed sequentially or concurrently.
	•	The TaskManager handles task scheduling, executing fibers one by one or in parallel, depending on the system load.
	2.	Sequential Execution:
	•	By default, tasks are executed sequentially, with each fiber in a task completing before the next one begins.
	3.	Parallel Execution:
	•	Independent fibers within tasks can be run in parallel, utilizing the system’s processing power more effectively.
	4.	Fiber Yielding:
	•	Fibers yield control after completing their work, allowing other tasks or fibers to run. This provides fine-grained control over execution and ensures that resources are utilized efficiently.
	5.	Task Transitions:
	•	Tasks manage their own successors, handling transitions based on their current state (success, failure, warning).
	•	Tasks can also delegate control to other tasks dynamically (task chaining).

Getting Started

1. Installation

To use the Multitasking Engine (MTE) in your project, follow these steps:

With Swift Package Manager (SPM)

If you’re using Swift Package Manager, add the TaskManagerLib (the multitasking engine library) as a dependency in your Package.swift:

.package(url: "https://github.com/your-username/TaskManagerLib.git", from: "1.0.0")

In your target, add:

.target(
    name: "YourTarget",
    dependencies: ["TaskManagerLib"]
)

Manual Installation

Alternatively, you can manually clone the repository and add the files to your project. Make sure to configure the dependencies correctly.

2. Using the TaskManager

Here’s a basic example of how to use the TaskManager and add tasks for execution:

import TaskManagerLib

// Define your tasks
let task1 = MockTask() // Create a mock task
let task2 = MockTask() // Create another mock task

// Create a TaskManager instance
let taskManager = TaskManager()

// Add tasks to the TaskManager
await taskManager.addTask(task1)
await taskManager.addTask(task2)

// Execute all tasks
await taskManager.executeAll()

Example Use Case: Sequential Task Execution

actor TaskManager {
    private var tasks: [TaskExecutable] = []
    
    func addTask(_ task: TaskExecutable) {
        tasks.append(task)
    }
    
    func executeAll() async {
        for task in tasks {
            await task.execute()
        }
    }
}

protocol TaskExecutable {
    func execute() async
}

struct MockTask: TaskExecutable {
    func execute() async {
        print("Task Executed")
    }
}

Task Flow Example

Here’s an example of how task flow can be managed, including error handling and successor handling:

actor TaskManager {
    private var tasks: [TaskExecutable] = []
    
    func addTask(_ task: TaskExecutable) {
        tasks.append(task)
    }
    
    func executeAll() async {
        for task in tasks {
            let result = await task.execute()
            
            switch result {
            case .success:
                // Continue to next task or fiber
                break
            case .failure(let error):
                // Handle error, possibly with an error handler
                break
            }
        }
    }
}

protocol TaskExecutable {
    func execute() async -> Result<Void, Error>
}

struct MockTask: TaskExecutable {
    func execute() async -> Result<Void, Error> {
        print("Task Executed")
        return .success(())
    }
}

Concurrency and Task Management

Task Scheduler and Yielding

The MTE provides an automatic task scheduler that manages the execution of fibers. When a fiber completes its work, it yields control, allowing other tasks or fibers to execute.

You can also set priorities for tasks and fibers, influencing how the task manager schedules and executes them.

Error Handling and Warnings

Tasks and fibers can encounter various scenarios:
	•	Success: The task proceeds as expected.
	•	Failure: An error occurs, and the task may need to pass control to an error handler.
	•	Warning: The task encounters a warning, but execution can continue.

Key Benefits of MTE
	•	Fine-Grained Task Control: Fibers allow for granular control over task execution.
	•	Efficient Resource Usage: Tasks and fibers can yield control, ensuring system resources are used efficiently.
	•	Easy Task Management: The TaskManager allows you to schedule, manage, and execute tasks in a sequential or parallel manner.

Testing the Multitasking Engine

Tests for the MTE can be written using Quick and Nimble. Here’s an example of testing the TaskManager:

import Quick
import Nimble
@testable import TaskManagerLib

class TaskManagerTests: QuickSpec {
    override func spec() {
        describe("TaskManager") {
            it("executes tasks sequentially") async {
                let taskManager = TaskManager()
                
                let task1 = MockTask()
                let task2 = MockTask()

                await taskManager.addTask(task1)
                await taskManager.addTask(task2)

                await taskManager.executeAll()

                expect(task1.isCompleted).to(beTrue())
                expect(task2.isCompleted).to(beTrue())
            }
        }
    }
}

Conclusion

The Multitasking Engine (MTE) provides the ability to manage and execute tasks efficiently, supporting both sequential and parallel task execution. By leveraging fibers and actor-based concurrency, MTE allows for fine-grained control over task management, error handling, and multitasking.

With modular design, task scheduling, and fiber management, the MTE ensures that tasks and fibers are executed in the most efficient manner possible, supporting future expansion into more advanced multitasking techniques.
