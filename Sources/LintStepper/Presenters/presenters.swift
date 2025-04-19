//
//  presenters.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/14/25.
//

import MultitaskingEngine

protocol DebuggerFormatter { }

protocol DebuggerPresenter: DebuggerFormatter {
    init(uiStateController: UIStateController)
}

extension DebuggerFormatter {
    func formatEntityNameAndSnippet(
        name: String?,
        snippet: String?,
        context: OutputContext
    ) -> String {
        let terminalWidth = TerminalState.terminalWidth
        
        // Interpret "NULL" as metadata placeholder
        let isNull = name == "NULL"
        let name = isNull ? nil : name
        
        // Color is determined only by NULL-ness and context
        let color: String
        switch context {
        case .next(let isNullMetadata):
            color = isNullMetadata ? ANSI.red : ANSI.green
        case .history:
            color = ANSI.white
        case .capture:
            color = ANSI.black
        }
        
        switch (name, snippet) {
        case (nil, nil):
            return ""
            
        case (nil, let snippet?):
            let cleanedSnippet = snippet.replacingOccurrences(of: "\n", with: " ")
            return "\(color)\(cleanedSnippet)\(ANSI.reset)"
            
        case (let name?, nil):
            return "\(color)\(name)\(ANSI.reset)"
            
        case (let name?, let snippet?):
            let cleanedSnippet = snippet.replacingOccurrences(of: "\n", with: " ")
            let combined = "\(name) — \(cleanedSnippet)"
            
            let ellipsis = "…"
            let truncated = combined.strippingANSI.count > terminalWidth
            ? truncateWithANSI(combined, to: terminalWidth - 1) + ellipsis
            : combined
            
            return "\(color)\(truncated)\(ANSI.reset)"
        }
    }
}

final class RenderRowsPresenter: RenderRowProvider {
    private let uiController: UIStateController


    init(uiController: UIStateController) {
        self.uiController = uiController
    }
    
    var renderRows: [RenderRow] {
        uiController.debugger.renderRows
    }
}

protocol StepResultsProvider {
    var stepResults: [StepResult]  { get }
}
