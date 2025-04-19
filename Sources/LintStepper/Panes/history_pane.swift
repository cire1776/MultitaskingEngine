//
//  HistoryPane.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//

import Foundation

protocol HistoryPresenter {
    var renderRows: [RenderRow]  { get }
    var window: [RenderRow]      { get }
    var startingIndex: Int       { get }
    var adjustedStartingIndex: Int { get }

    func styleForStep(_ string: String, index: Int) -> String
    func styleForTick(_ tick: Int, index: Int) -> String
}

final class HistoryPane: Pane, Focusable, ScrollableSelectable,  HistoryPresenter {
    var type: PaneType = .history
    var name: String = "Lint History"

    var row: Int = 0
    var height: Int = 0
    var left: Int = 0
    var width: Int = 0

    var titleHeight: Int { title == nil ? 0 : 2 }
    var visibleHeight: Int { height - titleHeight }
    var contentTopRow: Int { row + titleHeight }

    let presenter: HistoryPanePresenter

    var scrollMode: VerticalScrollNavigator?
    var selection: Int? = nil
    var selectedStep: Int? {
        guard let selection = selection else { return nil }
        return self.renderRows[selection].stepIndex
    }
    var selectionLimit: Int { renderRows.count - 1 }
    var verticalScrollOffset = 0

    var highlightedStepIds: Set<UUID> = []

    let title: String?

    var lintPane: LintPane!
    var outputPane: OutputPane!

    var renderRows: [RenderRow] { presenter.renderRows }
    var window: [RenderRow] {
        let start = verticalScrollOffset
        let end = min(start + visibleHeight - 1, renderRows.count - 1)
        guard start <= end else { return [] }

        var slice = renderRows[start...end]
        if let first = slice.first, first is TickRenderRow {
            slice = slice.dropFirst()
        }

        return Array(slice)
    }

    var adjustedStartingIndex: Int {
        let index = verticalScrollOffset
        return (renderRows[index] is TickRenderRow) ? index + 1 : index
    }
    var startingIndex: Int { verticalScrollOffset }

    private var topMostTick: Int?
    private var latestTickIndex: Int?

    init (presenter: HistoryPanePresenter, title: String?=nil) {
        self.presenter = presenter
        self.title = title
        self.lintPane = LintPane(parent: self)
        self.outputPane = OutputPane(parent: self)
    }

    func reset() {
        selection = nil
    }

    func incrementSelectedLine() {
        if var workSelection = selection {
            workSelection += 1
            setSelection(workSelection)
        } else {
            setSelection(0)
        }
    }

    func decrementSelectedLine() {
        guard let current = selection, current > 0 else { return }
        setSelection(current - 1)
    }

    func incrementSelectedStep() {
        guard let selection = selection else { return }
        let currentRow = renderRows[selection]

        for row in renderRows[selection + 1..<renderRows.endIndex] {
            if row.stepIndex != currentRow.stepIndex {
                setSelection(row)
                return
            }
        }
    }

    func decrementSelectedStep() {
        guard let selection = selection else { return }
        let currentRow = renderRows[selection]

        for row in renderRows[renderRows.startIndex..<selection].reversed() {
            if row.stepIndex != currentRow.stepIndex {
                setSelection(row)
                return
            }
        }
    }

    func incrementSelectedTick() {
        guard let selection = selection else { return }
        
        for row in renderRows[selection + 1..<renderRows.endIndex] {
            if row is TickRenderRow {
                setSelection(row)
                return
            }
        }
        
        if let lastRow = renderRows.last {
            setSelection(renderRows.count - 1)
        }
    }
        
    func decrementSelectedTick() {
        guard let selection = selection else { return }

        for row in renderRows[0..<selection].reversed() {
            if row is TickRenderRow {
                setSelection(row)
                return
            }
        }
    }
    
//    func incrementSelectedPage() {
//        guard let selection = selection else { return }
//
//        let offsetInWindow = selection - verticalScrollOffset
//        let newSelection = min(selection + visibleHeight, selectionLimit)
//        
//        setSelection(newSelection, alignment: .offset(offsetInWindow))
//    }
//
//    func decrementSelectedPage() {
//        guard let selection = selection else { return }
//        let newSelection = max(selection - visibleHeight, 0)
//        setSelection(newSelection, alignment: .retainOffset)
//    }
    
    func scrollToTop() {
        guard !renderRows.isEmpty else { return }
        setSelection(0)
    }
    
    func scrollToBottom() {
        guard !renderRows.isEmpty else { return }
        setSelection(renderRows.count - 1)
    }
    
//    func setSelection(_ index: Int, alignment: ScrollAlignment = .automatic) {
//        guard index >= 0,
//              index <= selectionLimit else { return }
//        
//        var alignment = ScrollAlignment.automatic
//        
//        switch alignment {
//        case .retainOffset:
//            let offsetInWindow = (selection ?? 0) - verticalScrollOffset
//            alignment = .offset(offsetInWindow)
//        case let .offset(requestedOffset):
//            alignment = .offset(requestedOffset)
//        default:
//            break
//        }
//
//        selection = index
//        scrollToSelection(alignment: alignment)
//    }
//
//    func setSelection(_ renderRow: RenderRow) {
//        if let index = renderRows.firstIndex(where: {
//            $0.stepIndex == renderRow.stepIndex
//        }) {
//            setSelection(index)
//        }
//    }
    
    func scrollToBottomOfStep() {
        guard let selection = selection,
              selection <= selectionLimit else { return }
        
        let stepIndex = renderRows[selection].stepIndex
        
        var finalIndex = selectionLimit
        for i in selection + 1..<renderRows.count {
            if renderRows[i].stepIndex == stepIndex {
                finalIndex = i
                continue
            }
            setSelection(i - 1)
            return
        }
        
        setSelection(finalIndex)
    }
    
    func scrollToTopOfStep() {
        guard let selection = selection,
              selection > 0,
              selection <= selectionLimit else { return }
        
        let stepIndex = renderRows[selection].stepIndex
        
        var finalIndex: Int = 0
        for i in stride(from: selection - 1, to: 0, by: -1) {
            if renderRows[i].stepIndex == stepIndex {
                finalIndex = i
                continue
            }
            setSelection(i + 1)
            return
        }
        
        setSelection(finalIndex)
    }

    func scrollToTopOfTick() {
        guard let selection = selection,
              renderRows.count > 1,
              selection > 1
        else { return }
        
        var finalIndex = 0
        
        for i in stride(from: selection - 1, through: 1, by: -1) {
            if renderRows[i].tick == renderRows[selection].tick {
                finalIndex = i
                continue
            }
            setSelection(i + 1)
        }
        
        setSelection(finalIndex)
    }
    
    func scrollToBottomOfTick() {
        guard let selection = selection,
              renderRows.count > 1,
              selection < selectionLimit
        else { return }
        
        var finalIndex = selectionLimit
        
        for i in selection + 1...selectionLimit {
            if renderRows[i].tick == renderRows[selection].tick {
                finalIndex = i
                continue
            }
            setSelection(i + 1)
        }
        
        setSelection(finalIndex)
    }
    
    func scrollToTopOfPage() {
        setSelection(0, alignment: .offset(0))
    }
    
    func scrollToBottomOfPage() {
        setSelection(visibleHeight - 1, alignment: .offset(visibleHeight - 1))
    }
    
//    func scrollToSelection(alignment: ScrollAlignment = .automatic) {
//        guard let selection = selection else { return }
//
//        let adjustedHeight = visibleHeight - 1
//        let maxOffset = max(0, renderRows.count - adjustedHeight)
//
//        switch alignment {
//        case let .offset(requestedOffset):
//            verticalScrollOffset = max(0, selection - requestedOffset)
//
//        case .center:
//            let halfHeight = adjustedHeight / 2
//            verticalScrollOffset = max(0, selection - halfHeight)
//
//        default:
//            if selection < verticalScrollOffset + 1 {
//                verticalScrollOffset = max(0, selection - 1)
//            } else if selection >= verticalScrollOffset + visibleHeight - 1 {
//                verticalScrollOffset = selection - adjustedHeight + 1
//            }
//        }
//    }

    func isSelected(_ index: Int) -> Bool {
        return selection == index
    }

    func isHighlighted(_ index: Int) -> Bool {
        guard let selection = selection,
              renderRows.indices.contains(selection),
              renderRows.indices.contains(index),
              renderRows[selection] is StepRenderRow,
              renderRows[index] is StepRenderRow else { return false }

        let selectedStep = renderRows[selection].stepIndex
        return renderRows[index].stepIndex == selectedStep
    }

    func styleForStep(_ string: String, index: Int) -> String {
        var format: String = ""

        if isHighlighted(index) {
            format = ANSI.highlighted
        }

        if isSelected(index) {
            format = ANSI.selected
        }

        if presenter.isRecent(index) {
            format = isSelected(index) ? ANSI.recentSelected : ANSI.recent
        }

        return "\(format)\(string.strippingANSI)\(ANSI.reset)"
    }

    func styleForTick(_ tick: Int, index: Int) -> String {
        var line: String = "\(tick)"
        var format: String = ANSI.gray

        if isSelected(index) {
            format = ANSI.selected
        }

        if presenter.isRecent(index) {
            format = isSelected(index) ? ANSI.recentSelected : ANSI.recent
        }

        let leadingLength = (width - line.count) / 2
        let leading = String(repeating: BoxDrawing.singleHorizontal.rawValue, count: leadingLength - 1)
        let trailing = String(repeating: BoxDrawing.singleHorizontal.rawValue, count: leadingLength)
        return "\(format)\(leading) \(line.strippingANSI) \(trailing)\(ANSI.reset)"
    }

    func renderContents() {
        let dividerWidth = 1
        let totalContentWidth = width - dividerWidth
        let outputWidth = totalContentWidth / 2
        let historyWidth = totalContentWidth - outputWidth

        renderTitle()

        if !renderRows.isEmpty {
            renderStickyTick()
            lintPane.render(at: contentTopRow + 1, height: visibleHeight - 1, left: 2, width: historyWidth)
            outputPane.render(at: contentTopRow + 1, height: visibleHeight - 1, left: historyWidth + 3, width: historyWidth)
        }

        clearEmptyRows(width: historyWidth)
    }

    private func renderTitle() {
        let dividerWidth = 1
        let totalContentWidth = width - dividerWidth
        let outputWidth = totalContentWidth / 2
        let historyWidth = totalContentWidth - outputWidth
        let leftColumn = left + 1

        guard let title = title else { return }

        let paddedTitle = title.padding(to: historyWidth, ansiSafe: true)
        TerminalState.moveCursor(toRow: row, column: leftColumn)
        print(paddedTitle, terminator: "")

        TerminalState.moveCursor(toRow: row + 1, column: leftColumn - 2)
        print("├", terminator: "")
        print(String(repeating: "─", count: (historyWidth * 2) + width % 2), terminator: "")
        print("┤", terminator: "")

        TerminalState.moveCursor(toRow: row + 1, column: leftColumn + historyWidth - 1)
        print("┬", terminator: "")
    }
    
    fileprivate func renderStickyTick() {
        guard !renderRows.isEmpty else { return }
        
        if let topMostRow = renderRows[verticalScrollOffset] as? TickRenderRow {
            topMostTick = topMostRow.tick
            latestTickIndex = verticalScrollOffset
        }
        
        TerminalState.moveCursor(toRow: contentTopRow, column: 2)
        print(styleForTick(topMostTick ?? -1, index: latestTickIndex ?? 0))
    }
    
    private func clearEmptyRows(width: Int) {
        let divider = "\(ANSI.gray)│\(ANSI.reset)"

        let occupiedRows = window.count
        
        for i in occupiedRows..<visibleHeight {
            let y = contentTopRow + (occupiedRows == 0 ? 0 : 1) + i // 1 to skip over stick tick rown
            TerminalState.moveCursor(toRow: y, column: 2)
            print(String(repeating: " ", count: width), terminator: "")
            TerminalState.moveCursor(toRow: y, column: 2 + width)
            print(divider, terminator: "")
            TerminalState.moveCursor(toRow: y, column: 2 + width + 1)
            print(String(repeating: " ", count: width), terminator: "")
        }
    }

    func visibleRowRange() -> Range<Int>? {
        let totalRows = renderRows.count
        guard totalRows > 0 else { return nil }

        let start = verticalScrollOffset
        let end = min(start + height, totalRows)

        return start..<end
    }

    func renderSelectionIndicator() {
        _renderSelectionIndicator()
    }

    func renderBox(at row: Int, height: Int, left: Int, width: Int) {
        _renderBox(at: row, height: height, left: left, width: width)
    }

    func rangeForStep(_ stepIndex: Int) -> Range<Int>? {
        let rows = presenter.renderRows
        let matches = rows.enumerated().filter { $0.element.stepIndex == stepIndex }.map(\.offset)
        guard let first = matches.first, let last = matches.last else { return nil }
        return first..<(last + 1)
    }
}
