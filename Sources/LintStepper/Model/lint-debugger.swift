//
//  lint-debugger.swift
//  MultitaskingEngine
//
//  Updated by ChatGPT on 4/12/25
//

import Foundation
import MultitaskingEngine
import TestHelpers

nonisolated(unsafe) var shouldStopCapture = false
nonisolated(unsafe) var pause = false

#if DEBUG
import Darwin

struct ExecutionContextSnapshot {
    let tick: Int
    let mode: ExecutionMode
    let subscriptions: Subscriptions
    let variables: [String: VariableSummary]
}

struct StepResult {
    let metadata: LintMetadata
    let result: OperationState
    let output: String
    let executionContextSnapshot: ExecutionContextSnapshot
    let id: UUID = UUID()
}

final class LintDebugger: RenderRowProvider {
    private let runner: ManualLintRunner
    private let context: StreamExecutionContext
    
    private(set) var stepResults: [StepResult] = []
    
    var stepResultsVisitor: (([StepResult]) -> Void)?
    
    var history: [LintMetadata] = []
    var recentStepResultIDs: Set<UUID> = []
    
    var currentMetadata: LintMetadata {
        runner.table.metadata(runner: runner)
    }
    
    private(set) var renderRows: [RenderRow] = []
    
    var isCapturing = false
    
    init(runner: ManualLintRunner, context: StreamExecutionContext) {
        self.context = context
        self.runner = runner
        self.runner.lintVisitor = self.recordLintEvent
    }
    
    func isRecent(index: Int) -> Bool {
        let stepResult = stepResults[index]
        return recentStepResultIDs.contains(stepResult.id)
    }
    
    func recordLintEvent(meta: LintMetadata, result: OperationState) {
        // intentionally unused in final stepResults version
    }
    
    func reset() {
        runner.lintCounter = 0
        runner.previousTableNode = nil
        stepResults.removeAll()
        renderRows.removeAll()
        isCapturing = false
        history.removeAll()
        recentStepResultIDs.removeAll()
    }
    
    func step(times count: Int = 1) async {
        recentStepResultIDs = []
        for _ in 0..<count {
            await _step()
        }
    }
    
    private func _step() async {
        let metadata = runner.table.metadata(runner: runner)
        var result: OperationState = .firstRun
        
        let output = await captureStdOut {
            result = await runner.execute()
        }
        
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let snapshot = ExecutionContextSnapshot(tick: context.tick, mode: context.executionMode, subscriptions: context.subscriptions, variables: context.getAllVariables(at: context.tick))
        
        let stepResult = StepResult(
            metadata: metadata,
            result: result,
            output: trimmed,
            executionContextSnapshot: snapshot
        )
        
        stepResults.append(stepResult)
        recentStepResultIDs.insert(stepResult.id)
        
        if let stepResultsVisitor = stepResultsVisitor {
            stepResultsVisitor(stepResults)
        }
    }
    
    func bigStep() async {
        guard !isCapturing else { return }
        
        TerminalState.installInterruptHandler()
        shouldStopCapture = false
        isCapturing = true
        defer { isCapturing = false }
        
        recentStepResultIDs = []
        
        let currentTick = stepResults.last?.executionContextSnapshot.tick
        
        while true {
            if shouldStopCapture { break }
            await self._step()
            
            let step = stepResults.last
            guard  step?.result != .completed,
                step?.executionContextSnapshot.tick == currentTick else { break }
        }
    }
    
    func startCapture(interval: TimeInterval = 0.1) async {
        TerminalState.installInterruptHandler()
        shouldStopCapture = false
        isCapturing = true
        defer { isCapturing = false }
        
        recentStepResultIDs = []
        
        while true {
            if shouldStopCapture { break }
            if pause { try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000)); continue }
            await self._step()
            
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            
            if stepResults.last?.result == .completed {
                break
            }
        }
    }
}

class DummyTableProvider: RunnableLintProvider {
    var table: any MultitaskingEngine.LintTable.Steppable = LintTable.Loop(lints: [
            { _ in print ("a line of output"); return .running}
    ])
    
    var operationName = "Dummy"
    
}
#endif
