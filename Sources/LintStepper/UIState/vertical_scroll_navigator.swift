//  vertical_scroll_navigator.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

enum ScrollMode: Character {
    case line = "↕️"
    case step = "👣"
    case tick = "🕰️"
    case page = "📄"
}

protocol VerticalScrollNavigator {
    static func setScrollMode(command: Command, pane: inout ScrollableSelectable, uitStateController: UIStateController)
    
    var scrollMode: ScrollMode { get }
    var representation: Character { get }
    
    mutating func navigate(_ command: Command)
    mutating func bigStep(_ command: Command) async
}

extension VerticalScrollNavigator {
    static func setScrollMode(command: Command, pane: inout ScrollableSelectable, uitStateController: UIStateController) {
        switch command {
        case .setLineScrollMode:
            pane.scrollMode = VerticalScrollLineNavigator(pane: pane, uiStateController: uitStateController)
        case .setStepScrollMode:
            pane.scrollMode = VerticalScrollStepNavigator(pane: pane, uiStateController: uitStateController)
        case .setTickScrollMode:
            pane.scrollMode = VerticalScrollTickNavigator(pane: pane, uiStateController: uitStateController)
        case .setPageScrollMode:
            pane.scrollMode = VerticalScrollPageNavigator(pane: pane, uiStateController: uitStateController)
        default:
            return
        }
    }
}

struct VerticalScrollLineNavigator: VerticalScrollNavigator {
    var pane: ScrollableSelectable
    var uitStateController: UIStateController
    
    var scrollMode: ScrollMode = .line
    var representation: Character = ScrollMode.line.rawValue
    
    init(pane: ScrollableSelectable, uiStateController: UIStateController) {
        self.pane = pane
        self.uitStateController = uiStateController
    }
    
    mutating func navigate(_ command: Command) {
        switch command {
        case .scrollUp:
            pane.decrementSelectedLine()
        case .scrollDown:
            pane.incrementSelectedLine()
        case .scrollToTop:
            pane.scrollToTop()
        case .scrollToBottom:
            pane.scrollToBottom()
        default:
            break
        }
    }
    
    mutating func bigStep(_ command: Command) async {
        await uitStateController.debugger.step(times: 5)
    }
}

struct VerticalScrollStepNavigator: VerticalScrollNavigator {
    var pane: ScrollableSelectable
    var uitStateController: UIStateController
    
    var scrollMode: ScrollMode = .step
    var representation: Character = ScrollMode.step.rawValue
    
    init(pane: ScrollableSelectable, uiStateController: UIStateController) {
        self.pane = pane
        self.uitStateController = uiStateController
    }
    
    mutating func navigate(_ command: Command) {
        switch command {
        case .scrollUp:
            pane.decrementSelectedStep()
        case .scrollDown:
            pane.incrementSelectedStep()
        case .scrollToTop:
            pane.scrollToTopOfStep()
        case .scrollToBottom:
            pane.scrollToBottomOfStep()
        default:
            break
        }
    }
    
    mutating func bigStep(_ command: Command)  async {
        let times = await TerminalState.promptForNumber(prompt: "\(ANSI.white)How many steps?", default: 10) ?? 0
        await uitStateController.debugger.step(times: times)
    }
}

struct VerticalScrollTickNavigator: VerticalScrollNavigator {
    var pane: ScrollableSelectable
    var uitStateController: UIStateController
    
    var scrollMode: ScrollMode = .tick
    var representation: Character = ScrollMode.tick.rawValue
    
    init(pane: ScrollableSelectable, uiStateController: UIStateController) {
        self.pane = pane
        self.uitStateController = uiStateController
    }
    
    mutating func navigate(_ command: Command) {
        switch command {
        case .scrollUp:
            pane.decrementSelectedTick()
        case .scrollDown:
            pane.incrementSelectedTick()
        case .scrollToTop:
            pane.scrollToTopOfTick()
        case .scrollToBottom:
            pane.scrollToBottomOfTick()
        default:
            break
        }
    }
    
    mutating func bigStep(_ command: Command) async {
        await uitStateController.debugger.bigStep()
    }
}

struct VerticalScrollPageNavigator: VerticalScrollNavigator {
    var pane: ScrollableSelectable
    var uitStateController: UIStateController
    
    var scrollMode: ScrollMode = .page
    var representation: Character = ScrollMode.page.rawValue
    
    init(pane: ScrollableSelectable, uiStateController: UIStateController) {
        self.pane = pane
        self.uitStateController = uiStateController
    }
    
    mutating func navigate(_ command: Command) {
        switch command {
        case .scrollUp:
            pane.decrementSelectedPage()
        case .scrollDown:
            pane.incrementSelectedPage()
        case .scrollToTop:
            pane.scrollToTopOfPage()
        case .scrollToBottom:
            pane.scrollToBottomOfPage()
        default:
            break
        }
    }
    
    mutating func bigStep(_ command: Command)  async {
    }
}


