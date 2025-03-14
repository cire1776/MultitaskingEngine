//import Quick
//import Nimble
//@testable import ULangLib
//@testable import TestHelpers
//
//class TaskManagerTests: QuickSpec {
//    override func spec() {
//        describe("TaskManager") {
//            it("executes tasks sequentially", closure: {
//                // Create mock tasks with closures
//                let mockTask1 = MockTask()
//                let mockTask2 = MockTask()
//                
//                // Initialize the TaskManager actor
//                let taskManager = TaskManager()
//                
//                // Add tasks to the TaskManager
//                await taskManager.addTask(mockTask1)
//                await taskManager.addTask(mockTask2)
//                
//                // Execute all tasks
//                await taskManager.executeAll()
//                
//                // Check if tasks have been completed
//                expect(mockTask1.isCompleted).to(beTrue())
//                expect(mockTask2.isCompleted).to(beTrue())
//            })
//        }
//    }
//}
