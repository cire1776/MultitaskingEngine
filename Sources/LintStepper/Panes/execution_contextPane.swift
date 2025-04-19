//
//  ExecutionContextPane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

final class ExecutionContextPane: Pane, Focusable {
    var type: PaneType = .ec
    var name: String = "Execution Context"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0
    
    var visibleHeight: Int { height }
    
    var presenter: ExecutionContextPanePresenter
    
    var selection: Int? = nil
    var verticalScrollOffset: Int = 0
    var selectionLimit: Int { 0 }
    var scrollMode: VerticalScrollNavigator?
    
    var horizontalScrollOffset: Int = 0
    
    var status: ECStatusPane
    var subscriptions: ECSubscriptionsPane!
    var variables: ECVariablesPane!
    
    init(presenter: ExecutionContextPanePresenter) {
        self.presenter = presenter
        
        let subPanePresenter = ECPresenter(uiStateController: presenter.uiStateController)
        self.status = ECStatusPane(presenter: subPanePresenter)
        self.subscriptions = ECSubscriptionsPane(presenter: subPanePresenter, parent: self)
        self.variables = ECVariablesPane(presenter: subPanePresenter, parent: self)
    }
    
    func reset() {
        selection = nil
        horizontalScrollOffset = 0
    }
    
    func renderContents() {
        let row = self.row
        let startCol = TerminalState.terminalWidth - width + 1
        
        status.render(at: row, height: 10, left: left, width: width)
        subscriptions.render(at: row + 2, height: 10, left: left, width: width)
        variables.render(at: row + subscriptions.height + 3, height: height - 4, left: left, width: width)
        
        
//        // Keys (sorted and converted to String)
//        
//        let step: StepResult
//        if let selection = presenter.historySelection {
//            step = presenter.stepResults[selection]
//        } else {
//            guard let rawStep = presenter.stepResults.last else { return }
//            step = rawStep
//        }
//        
//        let summaries = step.executionContextSnapshot.variables
//        let keys = summaries.keys.sorted()
//        
//        let maxLabelWidth = keys.map(\.count).max() ?? 0
//        let contextStartRow = row + 3
//        let maxVisible = height - 3
//        
//        for (index, key) in keys.prefix(maxVisible).enumerated() {
//            let y = contextStartRow + index
//            guard y < row + height else { break }
//            
//            let label = key.padding(toLength: maxLabelWidth, withPad: " ", startingAt: 0)
//            let rawValue = String(describing: summaries[key]?.value ?? "")
//                .replacingOccurrences(of: "\n", with: " ")
//            
//            let fullLine = "\(label) = \(rawValue)"
//            let truncated = truncateWithANSI(fullLine, to: width)
//            let padded = truncated.padding(to: width, ansiSafe: true)
//            
//           TerminalState.moveCursor(toRow: y, column: startCol)
//            print(padded, terminator: "")
//        }
//        
//        // Clear remaining lines
//        for i in keys.count..<maxVisible {
//            let y = contextStartRow + i
//           TerminalState.moveCursor(toRow: y, column: startCol)
//            print(String(repeating: " ", count: width), terminator: "")
//        }
    }
    
    func renderSelectionIndicator() {
        print("\(ANSI.borderSelection)")
        _renderSelectionIndicator()
        print("\(ANSI.reset)")
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }
}

