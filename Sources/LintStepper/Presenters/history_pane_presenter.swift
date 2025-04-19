//
//  history_pane_presenter.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

import Foundation

struct HistoryPanePresenter: DebuggerPresenter {
    private let uiStateController: UIStateController
    
    init(uiStateController: UIStateController) {
        self.uiStateController = uiStateController
    }
    
    var stepResults: [StepResult] {
        uiStateController.debugger.stepResults
    }
    
    var historySelection: Int? {
        uiStateController.historyPane.selection
    }
    
    var renderRows: [RenderRow] {
        uiStateController.renderRows
    }
    
    func isRecent(_ index: Int) -> Bool {
        if let row = renderRows[index] as? TickRenderRow {
            return false
        } else if let row = renderRows[index] as? StepRenderRow {
            return uiStateController.debugger.isRecent(index: row.stepIndex)
        }
        return false
    }
}
