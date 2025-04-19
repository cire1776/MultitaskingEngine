//
//  FocusSubPaneNavigator.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

struct FocusSubPaneNavigator {
    let uiController: UIStateController
    
    func forwardSwitchSubPane() {
        guard let focusedPane = uiController.focusedPane else { return }
        
        switch focusedPane {
        case let pane as HistoryPane:
            uiController.focusedPane = pane.lintPane
        case let pane as LintPane:
            uiController.focusedPane = pane.parent.outputPane
        case let pane as OutputPane:
            uiController.focusedPane = pane.parent
        case let pane as ExecutionContextPane:
            uiController.focusedPane = pane.subscriptions
        case let pane as ECSubscriptionsPane:
            uiController.focusedPane = pane.parent.variables
        case let pane as ECVariablesPane:
            uiController.focusedPane = pane.parent
        default:
            break
        }
    }
    
    func reverseSwitchSubPane() {
        guard let focusedPane = uiController.focusedPane else { return }
        
        switch focusedPane {
        case _ as HistoryPane:
            uiController.focusedPane = uiController.nextLintPane
        case _ as NextLintPane:
            uiController.focusedPane = uiController.historyPane
        case let pane as ExecutionContextPane:
            uiController.focusedPane = pane.variables
        case let pane as ECSubscriptionsPane:
            uiController.focusedPane = pane.parent
        case let pane as ECVariablesPane:
            uiController.focusedPane = pane.parent.subscriptions
        default:
            break
        }
    }
}
