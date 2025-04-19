//
//  NextLintPanePresenter.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

import MultitaskingEngine

struct NextLintPanePresenter: DebuggerPresenter {
    private let uiStateController: UIStateController
    
    var metadata: LintMetadata? {
        uiStateController.debugger.currentMetadata
    }
    
    var formattedSourceString: String {
        let isNull = metadata?.isNull ?? true
        
        return formatEntityNameAndSnippet(
            name: String(describing: metadata?.name ?? "NULL"),
            snippet: metadata?.sourceSnippet ?? "",
            context: .next(isNullMetadata: isNull)
        )
    }
    
    init(uiStateController: UIStateController) {
        self.uiStateController = uiStateController
    }
}
