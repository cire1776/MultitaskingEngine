//
//  ExecutionContextPanePresenter.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


struct ExecutionContextPanePresenter: StepResultsProvider {
    let uiStateController: UIStateController
    
    init(uiController: UIStateController) {
        self.uiStateController = uiController
    }
    
    var stepResults: [StepResult] {
        uiStateController.debugger.stepResults
    }
    
    var historySelection: Int? {
        uiStateController.historyPane.selectedStep
    }
}
