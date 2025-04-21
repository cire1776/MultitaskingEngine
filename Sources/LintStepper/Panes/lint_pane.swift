//
//  LintPane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


final class LintPane: Pane, HorizontallyScrollable, Focusable {
    var type: PaneType = .lint
    var name: String = "Lints"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0
    
    var visibleHeight: Int { height }
    
    var parent: HistoryPane
    var presenter: HistoryPresenter
    
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
        let divider = "\(ANSI.gray)│\(ANSI.reset)"
        
        let rows = presenter.window
        var indentationLevel = 0

        for i in 0..<rows.count {
            let renderRow = rows[i]
            var line = ""
            
            switch renderRow {
            case let row as TickRenderRow:
                line = presenter.styleForTick(row.tick, index: i + presenter.startingIndex)
            case let row as ULangEntityRenderRow:
                let entityWidth = self.width
                line = presenter.styleForULangEntity(row.ULangEntity.sourceText, context: row.ULangEntity.sourceContext, index: i + presenter.adjustedStartingIndex)
                    .skipVisibleCharacters(horizontalScrollOffset)
                    .padding(to: entityWidth, ansiSafe: true)
                    .prefixVisibleCharacters(entityWidth, ellipsis: "…")
                    .appending(divider)
            case let row as StepRenderRow:
                let string = (String(String(repeating: "  ", count: indentationLevel)) + (row.left ?? ""))
                    .skipVisibleCharacters(horizontalScrollOffset)
                    .prefixVisibleCharacters(width, ellipsis: "…")
                    .padding(to: self.width, ansiSafe: true)
                line = presenter.styleForStep(string, index: i + presenter.adjustedStartingIndex)
                    .appending(divider)
            default:
                line = "---- Unknown RenderRow ----"
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
