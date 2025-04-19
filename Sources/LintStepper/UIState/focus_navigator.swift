//
//  FocusNavigator.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


struct FocusNavigator {
    var uiController: UIStateController
    
    func forwardSwitchPane() {
        guard let focusedPane = uiController.focusedPane else { return }
        
        switch focusedPane {
        case _ as HistoryPane, _ as LintPane, _ as OutputPane:
            uiController.focusedPane = uiController.executionContextPane
        case _ as ExecutionContextPane:
            uiController.focusedPane = uiController.nextLintPane
        case _ as NextLintPane:
            uiController.focusedPane = uiController.historyPane
        default:
            break
        }
    }
    
    func reverseSwitchPane() {
        guard let focusedPane = uiController.focusedPane else { return }
        
        switch focusedPane {
        case _ as HistoryPane, _ as LintPane, _ as OutputPane:
            uiController.focusedPane = uiController.nextLintPane
        case _ as ExecutionContextPane:
            uiController.focusedPane = uiController.historyPane
        case _ as NextLintPane:
            uiController.focusedPane = uiController.executionContextPane
        default:
            break
        }
    }
}
