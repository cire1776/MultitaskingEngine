//
//  OutputPane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


final class OutputPane: Pane, HorizontallyScrollable, Focusable {
    var type: PaneType = .output
    var name: String = "Output"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0
    
    var visibleHeight: Int { height }
    
    let parent: HistoryPane
    let presenter: HistoryPresenter
    
    var horizontalScrollOffset: Int = 0
    var verticalScrollOffset: Int = 0
    
    var selection: Int? = nil
    
    init(parent: HistoryPane) {
        self.parent = parent
        self.presenter = parent
    }
    
    func reset() {
        horizontalScrollOffset = 0
        verticalScrollOffset = 0
        selection = nil
    }
    
    func renderContents() {
        let rows = presenter.window

        for i in 0..<rows.count {
            let renderRow = rows[i]
            var line = ""
            switch renderRow {
            case is TickRenderRow:
                continue
            case let row as StepRenderRow:
                let string = (row.right ?? "~empty")
                    .skipVisibleCharacters(horizontalScrollOffset)
                    .prefixVisibleCharacters(width - 1, ellipsis: "…")
                    .padding(to: self.width, ansiSafe: true)
                
                line = presenter.styleForStep(string, index: i + presenter.adjustedStartingIndex)
            default:
                continue
            }
            
            TerminalState.moveCursor(toRow: row + i, column: left)
            print(line, terminator: "")
            print(ANSI.reset)
        }
    }
    
    func renderSelectionIndicator() {
        _renderSelectionIndicator()
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }
}

