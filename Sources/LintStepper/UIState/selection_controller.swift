//
//  selection_controller.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/18/25.
//

protocol SelectionController {
    static func setSelectionMode(command: Command, pane: inout HasSelection, uitStateController: UIStateController)
    
    var scrollMode: ScrollMode { get }
    var representation: Character { get }
    
    mutating func select(_ command: Command)
}

extension SelectionController {
    static func setSelectionMode(command: Command, pane: inout HasSelection, uitStateController: UIStateController) {
        switch command {
        case .setLineScrollMode:
            pane.selectionMode = NonScrollableLineSelectionController(pane: pane, representation: ScrollMode.line.rawValue)
        case .setPageScrollMode:
            pane.selectionMode = NonScrollablePageSelectionController(pane: pane, representation: ScrollMode.page.rawValue)
        default:
            return
        }
    }
}

struct NonScrollableLineSelectionController: SelectionController {
    var scrollMode: ScrollMode = .line
    var pane: HasSelection
    var representation: Character
    
    mutating func select(_ command: Command) {
        switch command {
        case .scrollDown:
            pane.incrementSelectedLine()
        case .scrollUp:
            pane.decrementSelectedLine()
        case .scrollToTop:
            pane.decrementSelectedPage()
        case .scrollToBottom:
            pane.incrementSelectedPage()
        default:
            break
        }
    }
}

struct NonScrollablePageSelectionController: SelectionController {
    var scrollMode: ScrollMode = .line
    var pane: HasSelection
    var representation: Character
    
    mutating func select(_ command: Command) {
        switch command {
        case .scrollDown:
            pane.incrementSelectedPage()
        case .scrollUp:
            pane.decrementSelectedPage()
        default:
            break
        }
    }
}
