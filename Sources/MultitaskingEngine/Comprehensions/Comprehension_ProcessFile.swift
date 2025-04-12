//
//  Comprehension_ProcessFile.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//

final class Comprehension_ProcessFile {
    let executionContext: StreamExecutionContext

    private let readLine: ReadLineFromFile
    private let addTerminator: AddLineEnding
    private let printLine: Print
    private let storeLine: AddLineToBuffer

    init(executionContext: StreamExecutionContext) {
        self.executionContext = executionContext

        readLine = ReadLineFromFile(
            aliasMap: ["input": "filename", "output": "line"],
            executionContext: executionContext,
            subscriptions: 0x0,
            publishes: 0x0
)

        addTerminator = AddLineEnding(
            aliasMap: ["input": "line"],
            executionContext: executionContext,
            subscriptions: 0x0,
            publishes: 0x0

        )

        printLine = Print(
            aliasMap: ["input": "line"],
            executionContext: executionContext,
            subscriptions: 0x0,
            publishes: 0x0
        )

        storeLine = AddLineToBuffer(
            aliasMap: ["input": "line", "output": "output"],
            executionContext: executionContext,
            subscriptions: 0x0,
            publishes: 0x0

        )
    }

    func execute() -> EntityResult {
        readLine.initialize()
        storeLine.initialize()
        // Print requires no initialization

        executionLoop: while true {
            tickLoop: repeat {
                switch readLine.next() {
                case .proceed, .pump(_):
                    break
                    
                case .eof:
                    break executionLoop
                    
                case .unusualExecutionEvent:
                    return .unusualExecutionEvent
                    
                case .notAvailable:
                    break tickLoop
                }
                
                _ = printLine.process()
                
                switch addTerminator.process() {
                case .proceed, .pump(_):
                    break
                    
                case .notAvailable:
                    break tickLoop
                    
                case .eof:
                    break executionLoop
                
                case .unusualExecutionEvent:
                    return .unusualExecutionEvent
                }
                
                switch storeLine.process() {
                case .proceed, .pump(_):
                    break
                    
                case .notAvailable:
                    break tickLoop
                    
                case .eof:
                    break executionLoop
                    
                case .unusualExecutionEvent:
                    return .unusualExecutionEvent
                }
            } while false
            
            executionContext.endTick()
        }
        
        readLine.finalize()
        
        return .proceed
    }
}
