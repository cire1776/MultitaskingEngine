//
//  NextLintPane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


final class NextLintPane: Pane, HorizontallyScrollable, Focusable {
    var type: PaneType = .next
    var name: String = "Next Lint"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0

    var visibleHeight: Int { height }
    
    private let presenter: NextLintPanePresenter
    
    var horizontalScrollOffset: Int = 0
    
    init(presenter: NextLintPanePresenter) {
        self.presenter = presenter
    }
    
    func reset() {
        horizontalScrollOffset = 0
    }
    
    func renderContents() {
        let meta = presenter.metadata
        guard let meta = meta else { return }
        
        let truncated = truncateWithANSI(presenter.formattedSourceString, to: width)
            .padding(to: width, ansiSafe: true)
        
        TerminalState.moveCursor(toRow: row, column: 2)
        print(truncated, terminator: "")
    }
    
    func renderSelectionIndicator() {
        _renderSelectionIndicator()
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }
}
