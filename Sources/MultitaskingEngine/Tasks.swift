//
//  Tesks.swift
//  ULang
//
//  Created by Eric Russell on 2/27/25.
//

protocol TaskExecutable {
    // A method to execute the task (or fiber)
    mutating func execute() -> Bool

    // The state of the task (can be used to check if the task is done)
    var isCompleted: Bool { get set }
}
