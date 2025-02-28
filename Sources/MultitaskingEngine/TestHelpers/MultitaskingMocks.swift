//
//  MulttaskingMocks.swift
//  ULang
//
//  Created by Eric Russell on 2/27/25.
//

@testable import ULangLib

// Mock Task class for testing, exposing only necessary methods for testing
struct MockTask: TaskExecutable, Sendable {
    var isCompleted: Bool = false

    // Simulating execution
    mutating func execute() -> Bool {
//        isCompleted = true
        return true
    }

    func setSuccessor(_ successor: @escaping () -> TaskExecutable) {
        // No successor needed for this test
    }

    var errorHandler: (@Sendable () -> Void)?
    var warningHandler: (@Sendable () -> Void)?
}
