//
//  horizontal_scroll_navigator.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

struct HorizontalScrollNavigator {
    var pane: HorizontallyScrollable
    
    init(pane: HorizontallyScrollable) {
        self.pane = pane
    }
    
    mutating func navigate(_ command: Command) {
        if command == .scrollLeft {
            pane.horizontalScrollOffset += 1
        } else if command == .scrollRight {
            pane.horizontalScrollOffset = max(0, pane.horizontalScrollOffset - 1)
        }
    }
}

