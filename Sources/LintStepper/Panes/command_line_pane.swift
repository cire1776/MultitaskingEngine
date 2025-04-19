//
//  CommandLinePane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


final class CommandLinePane: Pane {
    var type: PaneType = .commandLine
    var name: String = "Command Prompt"
    
    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0
    
    var visibleHeight: Int { height }
    
    var uiStateController: UIStateController
    
    init(uiStateController: UIStateController) {
        self.uiStateController = uiStateController
    }
    
    func reset() { }
    
    func renderContents() {
        let prompt = "[n] step   [c] capture   [space] pause   [r] reset   [q] quit"
        let padded = prompt.padding(to: TerminalState.terminalWidth, ansiSafe: true)
        TerminalState.moveCursor(toRow: self.height - 1, column: 3)
        print(padded, terminator: "")
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        let row = height - 2
        
        print("\(ANSI.invert)\(ANSI.aloeWash)")
        for _ in 0..<height {
            TerminalState.moveCursor(toRow: row, column: left)
            print(String(repeating: " ", count: width), terminator: "")
        }
        print(ANSI.reset)

        TerminalState.moveCursor(toRow: row, column: left)
        print("\(ANSI.aloeWashBackground)\(ANSI.white)\(self.name)\(ANSI.reset)")
    }
}
