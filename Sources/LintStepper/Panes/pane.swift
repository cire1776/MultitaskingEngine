//
//  pane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/14/25.
//

import Foundation

enum PaneType: CaseIterable {
    case status
    case next
    case history
    case lint
    case output
    case ec
    case commandLine
    case ecStatus
    case ecSubscriptions
    case ecVariables
}

enum ScrollAlignment {
    case automatic
    case offset(Int)
    case retainOffset
    case center
}

enum PaneHelpers {
}
protocol Pane: AnyObject {
    var type: PaneType { get }
    var name: String { get }
    
    var row: Int { get set }
    var height: Int { get set }
    var left: Int { get set }
    var width: Int { get set }
    
    var visibleHeight: Int { get }
    
    func reset()
    
    func render(at row: Int, height: Int, left: Int, width: Int)
    func renderContents()
    func renderBox(at row: Int, height: Int, left: Int, width: Int)
}

extension Pane {
    func render(at row: Int, height: Int, left: Int, width: Int) {
        self.row = row
        self.height = height
        self.left = left
        self.width = width
        
        renderContents()
    }
}

protocol Printer {
    func print(_ items: Any..., separator: String, terminator: String)
}

extension Printer {
    func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        for (i, item) in items.enumerated() {
            let output: Any
            
            if let string = item as? String {
                output = string.strippingANSI
            } else {
                output = item
            }
            
            Swift.print(output, terminator: i == items.count - 1 ? terminator : separator)
        }
    }
}

extension Pane {
    func _renderSelectionIndicator() {
        // geometry is based upon contents and needs to be adjusted for border
        let top = row - 1
        let bottom = row + height   
        let leftEdge = left - 1
        let rightEdge = left + width

        let h = BoxDrawing.doubleHorizontal.rawValue
        let v = BoxDrawing.doubleVertical.rawValue
        let tl = BoxDrawing.doubleTopLeft.rawValue
        let tr = BoxDrawing.doubleTopRight.rawValue
        let bl = BoxDrawing.doubleBottomLeft.rawValue
        let br = BoxDrawing.doubleBottomRight.rawValue

        // Top border
        TerminalState.moveCursor(toRow: top, column: leftEdge)
        print(ANSI.borderSelection + tl + String(repeating: h, count: width) + tr + ANSI.reset)

        // Sides
        for y in (top + 1)..<bottom {
            TerminalState.moveCursor(toRow: y, column: leftEdge)
            print(ANSI.borderSelection + v + ANSI.reset, terminator: "")
            TerminalState.moveCursor(toRow: y, column: rightEdge)
            print(ANSI.borderSelection + v + ANSI.reset)
        }

        // Bottom border
        TerminalState.moveCursor(toRow: bottom, column: leftEdge)
        print(ANSI.borderSelection + bl + String(repeating: h, count: width) + br + ANSI.reset)
    }
    
    func _renderBox(at row: Int, height: Int, left: Int, width: Int) {
        let horizontal = "─"
        let vertical = "│"
        let corner = "•"

        // Top border
        TerminalState.moveCursor(toRow: row, column: left)
        print("\(corner) \(self.name) \(String(repeating: horizontal, count: width - 4 - self.name.count))\(corner)")

        // Side borders
        if height > 1 {
            for y in (row + 1)..<row + height - 1 {
                TerminalState.moveCursor(toRow: y, column: left)
                print(vertical, terminator: "")
                TerminalState.moveCursor(toRow: y, column: left + width - 1)
                print(vertical)
            }
            
            // Bottom border
            TerminalState.moveCursor(toRow: row + height - 1, column: left)
            print("\(corner)\(String(repeating: horizontal, count: width - 2))\(corner)")
        }
    }
}

protocol HorizontallyScrollable {
    var horizontalScrollOffset: Int { get set }
}

protocol VerticallyScrollable: AnyObject {
    var scrollMode: VerticalScrollNavigator? { get set }
    
    var verticalScrollOffset: Int { get set }
    
    func scrollToSelection(alignment: ScrollAlignment)
    
    func scrollToTop()
    func scrollToBottom()

    func scrollToTopOfStep()
    func scrollToBottomOfStep()
    
    func scrollToTopOfTick()
    func scrollToBottomOfTick()
    
    func scrollToTopOfPage()
    func scrollToBottomOfPage()
}

protocol HasSelection: AnyObject {
    var selection: Int? { get set }
    var selectionLimit: Int { get }
    
    var selectionMode: SelectionController? { get set }
    
    func setSelection(_ index: Int, alignment: ScrollAlignment)
    func incrementSelectedLine()
    func decrementSelectedLine()
    
    func incrementSelectedStep()
    func decrementSelectedStep()
    
    func incrementSelectedTick()
    func decrementSelectedTick()
    
    func incrementSelectedPage()
    func decrementSelectedPage()
    
}

protocol HasRenderRows: AnyObject {
    var renderRows: [RenderRow]  { get }
}

protocol ScrollableSelectable: Pane, HasRenderRows {
    var selection: Int? { get set }
    var selectionLimit: Int { get }
    var scrollMode: VerticalScrollNavigator? { get set }
    
    func setSelection(_ index: Int, alignment: ScrollAlignment)
    func incrementSelectedLine()
    func decrementSelectedLine()
    
    func incrementSelectedStep()
    func decrementSelectedStep()
    
    func incrementSelectedTick()
    func decrementSelectedTick()
    
    func incrementSelectedPage()
    func decrementSelectedPage()
    
    var verticalScrollOffset: Int { get set }
    
    func scrollToSelection(alignment: ScrollAlignment)
    
    func scrollToTop()
    func scrollToBottom()

    func scrollToTopOfStep()
    func scrollToBottomOfStep()
    
    func scrollToTopOfTick()
    func scrollToBottomOfTick()
    
    func scrollToTopOfPage()
    func scrollToBottomOfPage()
}

extension ScrollableSelectable {
    func incrementSelectedPage() {
        guard let selection = selection else { return }
        let newSelection = min(selection + visibleHeight, selectionLimit)
        setSelection(newSelection, alignment: .retainOffset)
    }

    func decrementSelectedPage() {
        guard let selection = selection else { return }
        let newSelection = max(selection - visibleHeight, 0)
        setSelection(newSelection, alignment: .retainOffset)
    }

    func scrollToSelection(alignment: ScrollAlignment = .automatic) {
        guard let selection = selection else { return }

        let adjustedHeight = visibleHeight - 1
        let maxOffset = max(0, renderRows.count - adjustedHeight)

        switch alignment {
        case let .offset(requestedOffset):
            verticalScrollOffset = max(0, min(selection - requestedOffset, maxOffset))

        case .center:
            let halfHeight = adjustedHeight / 2
            verticalScrollOffset = max(0, min(selection - halfHeight, maxOffset))

        default:
            if selection < verticalScrollOffset + 1 {
                verticalScrollOffset = max(0, selection - 1)
            } else if selection >= verticalScrollOffset + visibleHeight - 1 {
                verticalScrollOffset = min(selection - adjustedHeight + 1, maxOffset)
            }
        }
    }

    func setSelection(_ index: Int, alignment: ScrollAlignment = .automatic) {
        guard index >= 0, index <= selectionLimit else { return }

        let offsetInWindow: Int

        switch alignment {
        case .retainOffset:
            offsetInWindow = (selection ?? 0) - verticalScrollOffset
        case let .offset(requestedOffset):
            offsetInWindow = requestedOffset
        default:
            offsetInWindow = 0
        }

        selection = index
        scrollToSelection(alignment: .offset(offsetInWindow))
    }
    
    func setSelection(_ renderRow: RenderRow, alignment: ScrollAlignment = .automatic) {
        guard let index = renderRows.firstIndex(where: { $0 === renderRow }) else { return }
        setSelection(index, alignment: alignment)
    }
}

protocol Focusable {
    func renderSelectionIndicator()
}
