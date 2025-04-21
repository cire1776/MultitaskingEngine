//
//  UIStateController.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

import Foundation
import MultitaskingEngine

final class UIStateController: RenderRowProvider, DebuggerFormatter {
    var debugger: LintDebugger
    var context: StreamExecutionContext
    var ui: TextUI
    
    var renderRows: [RenderRow] = []
    
    // MARK: - Individual Panes
    var statusPane: StatusPane!
    var nextLintPane: NextLintPane!
    var historyPane: HistoryPane!
    var executionContextPane: ExecutionContextPane!
    var commandLinePane: CommandLinePane!
    
    var focusedPane: Focusable?
    
    init (debugger: LintDebugger, context: StreamExecutionContext, ui: TextUI) {
        self.debugger = debugger
        self.context = context
        self.ui = ui
        
        self.statusPane = StatusPane(uiStateController: self)
        self.nextLintPane = NextLintPane(presenter: NextLintPanePresenter(uiStateController: self))
        self.historyPane = HistoryPane(presenter: HistoryPanePresenter(uiStateController: self), title: "Lint History")
        self.executionContextPane = ExecutionContextPane(presenter: ExecutionContextPanePresenter(uiController: self))
        self.commandLinePane = CommandLinePane(uiStateController: self)
        
        self.focusedPane = historyPane
        
        self.debugger.stepResultsVisitor = { self.handleAddedStepResults(stepResults: $0)
        }
        self.historyPane.scrollMode = VerticalScrollLineNavigator(pane: self.historyPane, uiStateController: self)
    }
    
    func reset() {
        self.statusPane.reset()
        self.nextLintPane.reset()
        self.historyPane.reset()
        self.executionContextPane.reset()
        self.commandLinePane.reset()
    }
    
    func renderIfNeeded() -> Void {
        if needRender {
            ui.render(uiStateController: self)
            needRender = false
        }
    }
    
    func handleCommand(_ command: Command) async {
        switch command {
        case .escape:
            if focusedPane is HistoryPane {
                debugger.recentStepResultIDs.removeAll()
            }
        case .bigStep:
            await historyPane.scrollMode?.bigStep(command)
        case .forwardSwitchPane:
            FocusNavigator(uiController: self).forwardSwitchPane()
        case .reverseSwitchPane:
            FocusNavigator(uiController: self).reverseSwitchPane()
        case .forwardSwtichSubPane:
            FocusSubPaneNavigator(uiController: self).forwardSwitchSubPane()
        case .reverseSwitchSubPane:
            FocusSubPaneNavigator(uiController: self).reverseSwitchSubPane()
            
        case .scrollLeft, .scrollRight:
            guard let pane = focusedPane as? HorizontallyScrollable else { return }
            var navigator = HorizontalScrollNavigator(pane: pane)
            navigator.navigate(command)
        case .scrollUp, .scrollDown,.scrollToTop, .scrollToBottom:
            switch focusedPane {
            case let pane as VerticallyScrollable:
                guard var scrollMode = pane.scrollMode else { return }
                scrollMode.navigate(command)
            case let pane as ScrollableSelectable:
                guard var scrollMode = pane.scrollMode else { return }
                scrollMode.navigate(command)
            case let pane as HasSelection:
                guard var selectionMode = pane.selectionMode else { return }
                selectionMode.select(command)
            default:
                break
            }
        case .setLineScrollMode, .setStepScrollMode,
             .setTickScrollMode, .setPageScrollMode:
            switch focusedPane {
            case _ as VerticallyScrollable:
                fatalError("Not Implemented.")
            case var pane as ScrollableSelectable:
                VerticalScrollLineNavigator.setScrollMode(command: command, pane: &pane, uitStateController: self)
            case var pane as HasSelection:
                guard var selectionMode = pane.selectionMode else { return }
                selectionMode.select(command)
            default:
                break
            }
            break
        default:
            break
        }
    }
    
    func handleAddedStepResults(stepResults: [StepResult]) {
        guard let stepResult = stepResults.last else { return }
        
        let metadata = stepResult.metadata
        
        let label = formatEntityNameAndSnippet(
            name: String(describing: metadata.role),
            snippet: metadata.sourceSnippet,
            context: .history
        )
        
        let lines = stepResult.output.split(separator: "\n", omittingEmptySubsequences: false)
        
        let stepIdx = stepResults.count - 1 // The just-added step
        
        // Check for tick boundary
        var previousTick = -1
        if stepResults.count > 1 {
            previousTick = stepResults[stepResults.count - 2].executionContextSnapshot.tick
        }
        
        let tick = stepResult.executionContextSnapshot.tick
        if previousTick != tick {
            renderRows.append(TickRenderRow(tick: tick, stepIndex: stepIdx))
        }
        
        // Check for entity boundary
        var previousEntityID: ULangEntityID?
        if stepResults.count > 1 {
            previousEntityID = stepResults[stepResults.count - 2].metadata.uLangEntityID
        }
        
        let entityID: ULangEntityID = metadata.uLangEntityID
        if previousEntityID != entityID {
            let uLangEntity = ULangEntityMap[entityID] ?? ULangEntity(kind: .annotation, sourceText: "ULangEntity Not Found", sourceContext: "ULangEntity Not Found", file: "", range: SourceRange(start: SourcePosition(line: 0, column: 0), end: SourcePosition(line: 0, column: 0))) // .NULL
            renderRows.append(ULangEntityRenderRow(tick: tick, stepIndex: stepIdx, ULangEntity: uLangEntity))
        }
        
        // Check for empty output
        if lines.isEmpty {
            renderRows.append(StepRenderRow(stepIndex: stepIdx, tick: tick, left: label, right: nil))
        } else {
            renderRows.append(StepRenderRow(stepIndex: stepIdx, tick: tick, left: label, right: String(lines[0])))
            for line in lines.dropFirst() {
                renderRows.append(StepRenderRow(stepIndex: stepIdx, tick: tick, left: nil, right: String(line)))
            }
        }
        
        // Add to recent array
        historyPane.highlightedStepIds.insert(stepResult.id)
        
        // Handle selection
        if let renderRow = renderRows.last {
            historyPane.setSelection(renderRows.count - 1)
        }
    }
}
