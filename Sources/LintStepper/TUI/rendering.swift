//
//  rendering.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

import Darwin

extension TextUI {
    func render(uiStateController: UIStateController) {
        // 1. Clear the screen and home the cursor
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        
        // 2. Calculate layout dimensions
        let termWidth = TerminalState.terminalWidth
        let termHeight = TerminalState.terminalHeight
        let ecWidth = termWidth / 3
        let historyWidth = termWidth - ecWidth - 3 // 3: middle bar + borders
        let bodyHeight = termHeight - 9 // title + status + next (3 lines) + bottom + cmd
        
        TerminalState.moveCursor(toRow: 1, column: 1)
        print("XXX", terminator: "")

        // 3. Cursor-aligned rendering
        var row = 2
        
        uiStateController.statusPane.render(at: row, height: 1, left: 2, width: termWidth - 2)
        
        row += 2
        
        uiStateController.nextLintPane.render(at: row, height: 1, left: 2, width: historyWidth);
        
        uiStateController.executionContextPane.render(at: row, height: bodyHeight + 2, left: termWidth - ecWidth, width: ecWidth)
       
        row += 2
        
        uiStateController.historyPane.render(at: row, height: bodyHeight, left: 2, width: historyWidth)
        
        uiStateController.commandLinePane.render(at: 1, height: termHeight, left: 2, width: ecWidth)
        
        if self.displayBorders {
            renderBorders(at: 1, bodyHeight: bodyHeight + 1, width: termWidth, historyWidth: historyWidth, ecWidth: ecWidth)
            
            uiStateController.focusedPane?.renderSelectionIndicator()
        }
        
        fflush(stdout)
    }
    
    func renderLayout(uiStateController: UIStateController) {
        // 1. Clear the screen and home the cursor
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        
        // 2. Calculate layout dimensions
        let termWidth = TerminalState.terminalWidth
        let termHeight = TerminalState.terminalHeight
        let ecWidth = termWidth / 3
        let historyWidth = termWidth - ecWidth - 3 // 3: middle bar + borders
        let bodyHeight = termHeight - 10 // title + status + next (3 lines) + bottom + cmd
        
        // 3. Cursor-aligned rendering
        var row = 2
        
        uiStateController.statusPane.renderBox(at: row, height: 1, left: 2, width: termWidth - 2); row += 2
        
        let nextPaneRow = row
        uiStateController.nextLintPane.renderBox(at: row, height: 1, left: 2, width: termWidth - 2); row += 3
        
        let ecPaneRow = row
        uiStateController.executionContextPane.renderBox(at: row, height: bodyHeight, left: termWidth - ecWidth, width: ecWidth)
        
        let historyRow = row
        uiStateController.historyPane.renderBox(at: row, height: bodyHeight, left: 2, width: historyWidth)
        
        uiStateController.commandLinePane.renderBox(at: 1, height: termHeight + 1, left: 2, width: ecWidth)
        
        if self.displayBorders {
            renderBorders(at: 1, bodyHeight: bodyHeight + 2, width: termWidth, historyWidth: historyWidth, ecWidth: ecWidth)
            
            uiStateController.focusedPane?.renderSelectionIndicator()
        }
        
//        TerminalState.moveCursor(toRow: termHeight, column: 1)
//        print("", terminator: "")
    }
    
    func renderBorders(at row: Int, bodyHeight: Int, width: Int, historyWidth: Int, ecWidth: Int) {
        let totalWidth = TerminalState.terminalWidth
        let title = "LINT STEPPER"
        let padding = (totalWidth - title.count - 2) / 2
        let colDivider = historyWidth + 2
        
        let statusRow = row + 1
        let nextTopRow = statusRow + 1
        let nextContentRow = nextTopRow + 1
        let nextBottomRow = nextContentRow + 1
        let bodyStartRow = nextBottomRow + 1
        let bottomRow = bodyStartRow + bodyHeight - 1
        
        // 1. Top line ┌── title ──┐
        TerminalState.moveCursor(toRow: row, column: 1)
        print("┌", terminator: "")
        
        TerminalState.moveCursor(toRow: row, column: 4)
        print(BoxDrawing.singleHorizontalAndDown.rawValue, terminator: "")
        
        for col in 2..<padding + 1 {
            TerminalState.moveCursor(toRow: row, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: row, column: padding + 1)
        print(" \(title) ", terminator: "")
        let rightPadStart = padding + title.count + 3
        for col in rightPadStart..<totalWidth {
            TerminalState.moveCursor(toRow: row, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: row, column: totalWidth)
        print("┐", terminator: "")
        

        // 2. Vertical bars and column divider
        TerminalState.moveCursor(toRow: statusRow, column: 1)
        print("│", terminator: "")
        TerminalState.moveCursor(toRow: statusRow, column: totalWidth)
        print("│", terminator: "")
        
        for r in (row + 2)..<bottomRow {
            TerminalState.moveCursor(toRow: r, column: 1)
            print("│", terminator: "")
            TerminalState.moveCursor(toRow: r, column: colDivider)
            print("│", terminator: "")
            TerminalState.moveCursor(toRow: r, column: totalWidth)
            print("│", terminator: "")
        }
        
        // 3. ├──┬──┤ under status
        TerminalState.moveCursor(toRow: nextTopRow, column: 1)
        print("├", terminator: "")
        for col in 2..<colDivider {
            TerminalState.moveCursor(toRow: nextTopRow, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: nextTopRow, column: colDivider)
        print("┬", terminator: "")
        for col in (colDivider + 1)..<totalWidth {
            TerminalState.moveCursor(toRow: nextTopRow, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: nextTopRow, column: totalWidth)
        print("┤", terminator: "")
        
        // 4. ├──┼──┤ under next
        TerminalState.moveCursor(toRow: nextBottomRow, column: 1)
        print("├", terminator: "")
        for col in 2..<colDivider {
            TerminalState.moveCursor(toRow: nextBottomRow, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: nextBottomRow, column: colDivider)
        print("┼", terminator: "")
        for col in (colDivider + 1)..<totalWidth {
            TerminalState.moveCursor(toRow: nextBottomRow, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: nextBottomRow, column: totalWidth)
        print("┤", terminator: "")
        
        // 5. Bottom └──┴──┘
        TerminalState.moveCursor(toRow: bottomRow, column: 1)
        print("└", terminator: "")
        for col in 2..<colDivider {
            TerminalState.moveCursor(toRow: bottomRow, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: bottomRow, column: colDivider)
        print("┴", terminator: "")
        for col in (colDivider + 1)..<totalWidth {
            TerminalState.moveCursor(toRow: bottomRow, column: col)
            print("─", terminator: "")
        }
        TerminalState.moveCursor(toRow: bottomRow, column: totalWidth)
        print("┘", terminator: "")
        
        // Joiners for StatusPane
        TerminalState.moveCursor(toRow: row, column: 4)
        print(BoxDrawing.singleHorizontalAndDown.rawValue, terminator: "")
        TerminalState.moveCursor(toRow: row + 1, column: 4)
        print(BoxDrawing.singleVertical.rawValue, terminator: "")
        TerminalState.moveCursor(toRow: row + 2, column: 4)
        print(BoxDrawing.singleHorizontalAndUp.rawValue, terminator: "")
        
//        TerminalState.moveCursor(toRow: bottomRow, column: 1)
//        print(ANSI.hideCursor, terminator: "")
//        print("") // needed to fix irregularities
    }
}
