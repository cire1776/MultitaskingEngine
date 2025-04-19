//
//  StatusPane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

final class StatusPane: Pane {
    var type: PaneType = .status
    var name: String = "Status"
    
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
        var status = ""
        
//        if let pane = uiStateController.focusedPane as? VerticallyScrollable {
//            status += "\(pane.scrollMode?.representation ?? "❓")"
//        }
        let focusedPane = uiStateController.focusedPane
        
        if let focusedPane = focusedPane,
           focusedPane is VerticallyScrollable != focusedPane is HasSelection {
            if let pane = focusedPane as? VerticallyScrollable {
                status += "\(pane.scrollMode?.representation ?? "❓")"
            } else {
                guard let focusedPane = focusedPane as? HasSelection else {
                    return
                }
                status += "\(focusedPane.selectionMode?.representation ?? "❓")"
            }
        }
        
        TerminalState.moveCursor(toRow: row, column: left)
        print(status, terminator: "")
    }
    
    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }
}
