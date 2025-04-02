//
//  redirection.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/21/25.
//

//
//  redirection.swift
//
//
//  Created by Eric Russell on 2/14/25.
//

import Foundation

func captureStdOut(_ execute: () -> Void) -> String {
    let pipe = Pipe()
    let originalStdOut = dup(fileno(stdout))  // ✅ Save original stdout
    
    dup2(pipe.fileHandleForWriting.fileDescriptor, fileno(stdout))  // ✅ Redirect stdout
    execute()  // ✅ Run the function

    fflush(stdout)  // ✅ Flush stdout
    pipe.fileHandleForWriting.closeFile()  // ✅ Close the write end to signal EOF
    dup2(originalStdOut, fileno(stdout))  // ✅ Restore stdout
    close(originalStdOut)  // ✅ Close duplicate descriptor

    let data = pipe.fileHandleForReading.readDataToEndOfFile()  // ✅ Now safely reads all data
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

// Struct to hold redirection state
struct StdoutRedirector {
    let pipe: Pipe
    let fileHandle: FileHandle
    let originalStdout: Int32

    // Initializer to set up the redirection
    init() {
        self.pipe = Pipe()
        self.fileHandle = pipe.fileHandleForReading
        self.originalStdout = dup(STDOUT_FILENO)
    }
    
    // Redirect stdout to the pipe
    mutating func redirectToPipe() {
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    }
    
    // Restore stdout to the console
    func restoreToConsole() {
        dup2(originalStdout, STDOUT_FILENO)
    }
    
    // Read and return the captured output (non-blocking)
    func capturedOutput() -> String {
        var output = ""
        
        // Read available data from the pipe non-blocking
        let data = fileHandle.availableData
        output += String(data: data, encoding: .utf8) ?? ""
        
        return output
    }
}

// Usage Example:
func redirectionFromTheConsoleToAString() -> String {
    var redirector = StdoutRedirector()

    // Redirect stdout to the pipe
    redirector.redirectToPipe()
    
    // The output of print() will go to the pipe instead of the console
    print("This is captured in a string.")
    
    // Get the captured output
    let output = redirector.capturedOutput()
    
    // Restore stdout to the console
    redirector.restoreToConsole()

    return output
}
