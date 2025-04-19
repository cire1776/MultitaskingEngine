//
//  ECSubPanes.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/18/25.
//

import MultitaskingEngine

// MARK: - ECStatusPane

final class ECStatusPane: Pane {
    var type: PaneType = .ecStatus
    
    var presenter: ECPresenter

    var name: String = "Execution Context Status"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0
    
    var visibleHeight: Int { height }
    
    var tick: Int { presenter.isThereSelection ? presenter.tick : 0 }
    var executionMode: ExecutionMode { presenter.executionMode }

    init(presenter: ECPresenter) {
        self.presenter = presenter
    }
 
    func reset() {
    }
    
    func renderContents() {
        var row = row
        
        TerminalState.moveCursor(toRow: row, column: left)
        print("   ⛽️  Execution Context  \t🕰️ \(tick)".padding(to: width, ansiSafe: true), terminator: "")

        row += 1
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }
}

// MARK: - StreamInfo / StreamType

enum StreamType: String {
    case ephemeral, indexed, `static`
}

struct StreamState {
    var index: Int
    var source: Bool
    var available: Bool
    var exhausted: Bool
}


// MARK: - ECSubscriptionsPane

final class ECSubscriptionsPane: Pane, Focusable {
    var type: PaneType = .ecSubscriptions
    var parent: ExecutionContextPane
    var presenter: ECPresenter
    
    var name: String = "Execution Context Subscriptions"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0
    
    var visibleHeight: Int { height - 2 }
    
    var subscriptions: [String: StreamState] { presenter.subscriptions }
    
    init(presenter: ECPresenter, parent: ExecutionContextPane) {
        self.presenter = presenter
        self.parent = parent
    }
    
    func reset() {
    }
    
    func renderContents() {
        var row = self.row
        
        if subscriptions.isEmpty {
            row += 1 // guarantee a minimum 1 line height
        } else {
            for (key, subscription) in subscriptions.sorted(by: { $0.value.index < $1.value.index }) {
                let source = subscription.source ? "🚰" : ""
                
                let available = subscription.available ? "🟢" : "🔴"
                let exhausted = "🛏️"
                
                let line = " \(key.padding(toLength: 12, withPad: " ", startingAt: 0)): \(source)  \(available)  \(exhausted)"
                
                TerminalState.moveCursor(toRow: row, column: left)
                print(line.padding(to: width, ansiSafe: true), terminator: "")
                
                row += 1
            }
        }
        
        self.height = row - self.row
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }
    
    
    func renderSelectionIndicator() {
        _renderSelectionIndicator()
    }
}

// MARK: - ECVariablesPane

final class ECVariablesPane: Pane, Focusable, HorizontallyScrollable, HasSelection {
    func incrementSelectedStep() {
        
    }
    
    func decrementSelectedStep() {
        
    }
    
    func incrementSelectedTick() {
        
    }
    
    func decrementSelectedTick() {
        
    }

    var type: PaneType = .ecVariables

    var parent: ExecutionContextPane
    var presenter: ECPresenter
    
    var name: String = "Execution Context Variables"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0
    
    var visibleHeight: Int { height }
    
    var variables: [String: VariableSummary] { presenter.variables }

    var horizontalScrollOffset: Int = 0
    
    var selection: Int?
    var selectionLimit: Int { min(self.height, variables.count - 1) }
    var selectionMode: (any SelectionController)?

    init(presenter: ECPresenter, parent: ExecutionContextPane) {
        self.presenter = presenter
        self.parent = parent
        self.selectionMode = NonScrollableLineSelectionController(pane: self, representation: ScrollMode.line.rawValue)
    }
    
    func reset() {
        
    }
    
    func incrementSelectedLine() {
        guard let selection = selection else {
            self.selection = 0
            return
        }
        
        guard selection < selectionLimit else { return }

        self.selection! += 1
    }
    
    func decrementSelectedLine() {
        guard var selection = selection else {
            self.selection = 0
            return
        }
        
        if selection > 0 {
            self.selection! -= 1
        }
    }
    
    
    func incrementSelectedPage() {
        selection = selectionLimit
    }
    
    func decrementSelectedPage() {
        selection = 0
    }

    func setSelection(_ index: Int, alignment: ScrollAlignment) {
        guard let selection = selection,
              selection <= selectionLimit else { return }
        self.selection = index
    }
    
    func isSelected(index: Int) -> Bool {
        if selection == index {
            return true
        }
        return false
    }
    
    func renderContents() {
        var row = self.row
        
        TerminalState.moveCursor(toRow: row-1, column: left)  // -1 because the line is outside the content area
        print(String(repeating: "─", count: width), terminator: "")
        
        if variables.isEmpty {
            TerminalState.moveCursor(toRow: row + height / 2 - 1, column: left)
            print(
                ANSI.gray + ANSI.italic +
                "No Variables Defined".padding(to: width, centered: true, ansiSafe: true) +
                ANSI.reset
            )
        } else {
            for (i, variableName) in variables.keys.sorted().enumerated() {
                let rawValue = variables[variableName]?.value
                
                let valueString: String
                if let value = rawValue {
                    valueString = String(describing: value)
                } else {
                    valueString = "~nil~"
                }
                
                let availableWidth = width - 4 - variableName.count
                let scrolledValue = valueString.skipVisibleCharacters(horizontalScrollOffset)
                let valueDisplay = scrolledValue.prefixVisibleCharacters(availableWidth, ellipsis: "…")

                let line = " \(variableName): \(valueDisplay)"
                let paddedLine = line.padding(toLength: width, withPad: " ", startingAt: 0)
                let styledLine = isSelected(index: i) ? "\(ANSI.selected)\(paddedLine)\(ANSI.reset)" : line

                TerminalState.moveCursor(toRow: row, column: left)
                print(styledLine.padding(to: width, ansiSafe: true), terminator: "")
                row += 1
            }
        }
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }
    
    func renderSelectionIndicator() {
        _renderSelectionIndicator()
    }
}
