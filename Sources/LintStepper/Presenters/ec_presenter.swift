//
//  ec_presenter.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/18/25.
//

import Foundation
import MultitaskingEngine

struct ECPresenter: DebuggerPresenter {
    struct SubscriptionExporter {
        var subscriptions: [String: StreamState]
        
        init?(subscriptions: Subscriptions) {
            let subscriptions = subscriptions
            var subscriptionView: [String: StreamState] = [:]
            
            subscriptions.visit() { index, sources, available, exhausted in
                subscriptionView["Stream \(index)"] = StreamState(index: index, source: sources, available: available, exhausted: exhausted)
            }
            
            self.subscriptions = subscriptionView
        }
    }
    
    private var uiStateController: UIStateController
    private let executionContext: StreamExecutionContext
    
    var isThereSelection: Bool {
        uiStateController.historyPane.selection != nil
    }
    
    var tick: Int {
        if let selection = uiStateController.historyPane.selection {
            return uiStateController.historyPane.renderRows[selection].tick
        } else {
            fatalError("Check for selection before calling.")
        }
    }
    
    var executionMode: ExecutionMode {
        executionContext.executionMode
    }
    
    var subscriptions: [String: StreamState] {
        if let selection = uiStateController.historyPane.selection {
            let stepIndex = uiStateController.historyPane.renderRows[selection].stepIndex
            let currentStep = uiStateController.debugger.stepResults[stepIndex]
            let subscriptions = currentStep.executionContextSnapshot.subscriptions
            return SubscriptionExporter(subscriptions: subscriptions)?.subscriptions ?? [:]
        } else {
            return [:]
        }
    }
    
    var variables: [String: VariableSummary] {
        if let selection = uiStateController.historyPane.selection {
            let stepIndex = uiStateController.historyPane.renderRows[selection].stepIndex
            let currentStep = uiStateController.debugger.stepResults[stepIndex]
            return  currentStep.executionContextSnapshot.variables
        } else {
            return [:]
        }
    }
        
    init(uiStateController: UIStateController) {
        self.uiStateController = uiStateController
        self.executionContext = uiStateController.context
    }
}

