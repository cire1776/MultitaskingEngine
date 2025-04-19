////
////  oldDebugger.swift
////  MultitaskingEngine
////
////  Created by Eric Russell on 4/14/25.
////
//
////
////  lint-debugger.swift
////  MultitaskingEngine
////
////  Updated by ChatGPT on 4/12/25
////
//
//import Foundation
//import MultitaskingEngine
//import TestHelpers
//
//nonisolated(unsafe) var shouldStopCapture = false
//nonisolated(unsafe) var pause = false
//
//#if DEBUG
//import Darwin
//
//enum ANSI {
//    static let reset = "\u{001B}[0m"
//    static let bold = "\u{001B}[1m"
//    static let italic = "\u{001B}[3m"
//    static let invert = "\u{001B}[7m"
//
//    static func color(_ code: Int) -> String {
//        return "\u{001B}[\(code)m"
//    }
//
//    // Common colors
//    static let black = color(30)
//    static let red = color(31)
//    static let green = color(32)
//    static let yellow = color(33)
//    static let blue = color(34)
//    static let magenta = color(35)
//    static let cyan = color(36)
//    static let white = color(37)
//    static let gray = color(90)
//    static let teal = "\u{001B}[38;5;37m"
//    static let slateBlue = "\u{001B}[38;5;61m"
//    
//    // backgrounds
//    static let grayBackground = "\u{001B}[48;5;235m"
//    static let lightBackground = "\u{001B}[48;5;250m"
//    static let mintBackground = "\u{001B}[48;5;120m"
//    static let celadonBackground = "\u{001B}[48;5;194m"      // Very light green with yellow tint
//    static let paleMintBackground = "\u{001B}[48;5;157m"      // Soft mint
//    static let springFrostBackground = "\u{001B}[48;5;151m"   // Subdued green
//    static let seafoamBackground = "\u{001B}[48;5;152m"       // Mellow bluish green
//    static let avocadoBackground = "\u{001B}[48;5;186m"       // Greenish-tan pastel
//    static let aloeWashBackground = "\u{001B}[48;5;193m"      // Soft pastel green
//    
//    static let borderSelection = Self.teal
//}
//
//struct ExecutionContextSnapshot {
//    let variables: [String: VariableSummary]
//}
//
//struct StepResult {
//    let metadata: LintMetadata
//    let result: OperationState
//    let output: String
//    let executionContextSnapshot: ExecutionContextSnapshot
//    let id: UUID = UUID()
//}
//
//final class LintDebugger {
//    enum OutputContext {
//        case next(isNullMetadata: Bool)
//        case history
//        case capture
//    }
//    
//    private let runner: ManualLintRunner
//    private let context: StreamExecutionContext
//    
//    private(set) var stepResults: [StepResult] = []
//    
//    var history: [LintMetadata] = []
//    var executionContext: [String: String] = [:]
//    
//    var currentMetadata: LintMetadata {
//        runner.table.metadata(runner: runner)
//    }
//    
//    var historyHorizontalScrollOffset: Int = 0
//    var historyVerticalScrollOffset: Int = 0
//    var historySelection: Int? = nil
//    var highlightedStepIds: Set<UUID> = []
//    
//    var ouptutHorizontalScrollOffset: Int = 0
//    private(set) var historyRenderRows: [RenderRow] = []
//    
//    var isCapturing = false
//    
//    var paneSelection: Pane? = nil
//    
//    
//    init(runner: ManualLintRunner, context: StreamExecutionContext) {
//        self.context = context
//        self.runner = runner
//        self.runner.lintVisitor = self.recordLintEvent
//    }
//    
//    func recordLintEvent(meta: LintMetadata, result: OperationState) {
//        // intentionally unused in final stepResults version
//    }
//    
//    func reset() {
//        runner.lintCounter = 0
//        runner.previousTableNode = nil
//        stepResults.removeAll()
//        historyRenderRows.removeAll()
//        historyHorizontalScrollOffset = 0
//    }
//    
//    func step() async {
//        let metadata = runner.table.metadata(runner: runner)
//        var result: OperationState = .firstRun
//        
//        let output = await captureStdOut {
//            result = await runner.execute()
//        }
//        
//        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        let snapshot = ExecutionContextSnapshot(variables: context.getAllVariables(at: context.tick))
//        
//        let stepResult = StepResult(
//            metadata: metadata,
//            result: result,
//            output: trimmed,
//            executionContextSnapshot: snapshot
//        )
//        
//        stepResults.append(stepResult)
//        
//        historySelection = stepResults.count - 1
//        
//        let label = formatEntityNameAndSnippet(
//            name: String(describing: metadata.name),
//            snippet: metadata.sourceSnippet,
//            context: .history
//        )
//        
//        let lines = trimmed.split(separator: "\n", omittingEmptySubsequences: false)
//        
//        let stepIdx = stepResults.count - 1 // The just-added step
//        
//        if lines.isEmpty {
//            historyRenderRows.append(RenderRow(stepIndex: stepIdx, left: label, right: nil))
//        } else {
//            historyRenderRows.append(RenderRow(stepIndex: stepIdx, left: label, right: String(lines[0])))
//            for line in lines.dropFirst() {
//                historyRenderRows.append(RenderRow(stepIndex: stepIdx, left: nil, right: String(line)))
//            }
//        }
//        
//        self.highlightedStepIds.insert(stepResult.id)
//    }
//    
//    func startCapture(interval: TimeInterval = 0.1) async {
//        TerminalState.installInterruptHandler()
//        shouldStopCapture = false
//        isCapturing = true
//        defer { isCapturing = false }
//        
//        let oldCount = stepResults.count
//        
//        while true {
//            if shouldStopCapture { break }
//            if pause { try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000)); continue }
//            await self.step()
//            self.render()
//            
//            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
//            
//            if stepResults.last?.result == .completed {
//                break
//            }
//        }
//        
//        let newSteps = stepResults.suffix(from: oldCount)
//        let newIds = newSteps.map(\.id)
//        self.highlightedStepIds.formUnion(newIds)
//    }
//    
//    func formatEntityNameAndSnippet(
//        name: String?,
//        snippet: String?,
//        context: OutputContext
//    ) -> String {
//        let terminalWidth = TerminalState.terminalWidth
//        
//        // Interpret "NULL" as metadata placeholder
//        let isNull = name == "NULL"
//        let name = isNull ? nil : name
//        
//        // Color is determined only by NULL-ness and context
//        let color: String
//        switch context {
//        case .next(let isNullMetadata):
//            color = isNullMetadata ? ANSI.red : ANSI.green
//        case .history:
//            color = ANSI.white
//        case .capture:
//            color = ANSI.black
//        }
//        
//        switch (name, snippet) {
//        case (nil, nil):
//            return ""
//            
//        case (nil, let snippet?):
//            let cleanedSnippet = snippet.replacingOccurrences(of: "\n", with: " ")
//            return "\(color)\(cleanedSnippet)\(ANSI.reset)"
//            
//        case (let name?, nil):
//            return "\(color)\(name)\(ANSI.reset)"
//            
//        case (let name?, let snippet?):
//            let cleanedSnippet = snippet.replacingOccurrences(of: "\n", with: " ")
//            let combined = "\(name) — \(cleanedSnippet)"
//            
//            let ellipsis = "…"
//            let truncated = combined.strippingANSI.count > terminalWidth
//            ? truncateWithANSI(combined, to: terminalWidth - 1) + ellipsis
//            : combined
//            
//            return "\(color)\(truncated)\(ANSI.reset)"
//        }
//    }
//    
//    func styledLocation(from metadata: LintMetadata) -> String? {
//        guard let file = metadata.shortFilePath else { return nil }
//        
//        let styledFile = "\(ANSI.bold)\(ANSI.cyan)\(file)\(ANSI.reset)"
//        let gray = ANSI.gray
//        
//        if let line = metadata.line {
//            if let column = metadata.column {
//                return "\(styledFile):\(gray)\(line):\(column)\(ANSI.reset)"
//            } else {
//                return "\(styledFile):\(gray)\(line)\(ANSI.reset)"
//            }
//        } else {
//            return styledFile
//        }
//    }
//    
//    func renderHeader(title: String = "LINT STEPPER") {
//        let width = TerminalState.terminalWidth
//        let padding = (width - title.count - 2) / 2
//        let line = String(repeating: "═", count: padding) + " \(title) " +
//        String(repeating: "═", count: width - padding - title.count - 4 )
//        print("╔\(line)╗")
//    }
//    
//    func renderBottomBorder(at row: Int, historyWidth: Int, ecWidth: Int) {
//       TerminalState.moveCursor(toRow: row, column: 1)
//        print("└" +
//              String(repeating: "─", count: historyWidth) + "┴" +
//              String(repeating: "─", count: ecWidth) + "┘")
//    }
//    
//    func renderNextLine(formatted: String) {
//        let contentWidth = TerminalState.contentWidth
//        
//        let visibleLength = formatted.strippingANSI.count
//        let truncated = visibleLength > contentWidth
//        ? truncateWithANSI(formatted, to: contentWidth - 1) + "…"
//        : formatted
//        
//        let padding = String(repeating: " ", count: Swift.max(0, contentWidth - truncated.strippingANSI.count))
//        print("║\(truncated)\(padding)║")
//    }
//    
//    func renderHistoryLine(_ line: String) {
//        let width = TerminalState.terminalWidth
//        let clean = line.replacingOccurrences(of: "\n", with: " ")
//        let trimmed = clean.count > width
//        ? String(clean.prefix(width - 1)) + "…"
//        : clean
//        print(trimmed)
//    }
//    
//    func renderLocationLine(from metadata: LintMetadata) {
//        guard let location = styledLocation(from: metadata) else { return }
//        
//        let indent = String(repeating: " ", count: 7)
//        let maxWidth = TerminalState.contentWidth - indent.count
//        
//        let visibleLength = location.strippingANSI.count
//        let trimmed = visibleLength > maxWidth
//        ? String(location.prefix(maxWidth - 2)) + "…"
//        : location
//        
//        let final = indent + trimmed
//        let padAmount = TerminalState.contentWidth - final.strippingANSI.count
//        let padded = final + String(repeating: " ", count: Swift.max(0, padAmount))
//        
//        print("║\(padded)║")
//    }
//    
//    func buildRenderRows(limit: Int) -> [RenderRow] {
//        var rows: [RenderRow] = []
//        
//        for step in stepResults {
//            let label = formatEntityNameAndSnippet(
//                name: String(describing: step.metadata.name),
//                snippet: step.metadata.sourceSnippet,
//                context: .history
//            )
//            
//            let lines = step.output.split(separator: "\n", omittingEmptySubsequences: false)
//            
//            let stepIndex = stepResults.firstIndex(where: { $0.id == step.id }) ?? 0
//            
//            if lines.isEmpty {
//                historyRenderRows.append(RenderRow(stepIndex: stepIndex, left: label, right: nil))
//            } else {
//                historyRenderRows.append(RenderRow(stepIndex: stepIndex, left: label, right: String(lines[0])))
//                for line in lines.dropFirst() {
//                    historyRenderRows.append(RenderRow(stepIndex: stepIndex, left: nil, right: String(line)))
//                }
//            }
//            
//            if rows.count >= limit {
//                break
//            }
//        }
//        
//        return Array(rows.suffix(limit))
//    }
//    
//    // 1. App Title Bar
//    func renderBorders(at row: Int, bodyHeight: Int, historyWidth: Int, ecWidth: Int) {
//        let totalWidth = TerminalState.terminalWidth
//        let title = "LINT STEPPER"
//        let padding = (totalWidth - title.count - 2) / 2
//        let colDivider = historyWidth + 2
//        
//        let statusRow = row + 1
//        let nextTopRow = statusRow + 1
//        let nextContentRow = nextTopRow + 1
//        let nextBottomRow = nextContentRow + 1
//        let bodyStartRow = nextBottomRow + 1
//        let bottomRow = bodyStartRow + bodyHeight
//        
//        // 1. Top line ┌── title ──┐
//       TerminalState.moveCursor(toRow: row, column: 1)
//        print("┌", terminator: "")
//        for col in 2..<padding + 1 {
//           TerminalState.moveCursor(toRow: row, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: row, column: padding + 1)
//        print(" \(title) ", terminator: "")
//        let rightPadStart = padding + title.count + 3
//        for col in rightPadStart..<totalWidth {
//           TerminalState.moveCursor(toRow: row, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: row, column: totalWidth)
//        print("┐", terminator: "")
//        
//        
//        // 2. Vertical bars and column divider
//       TerminalState.moveCursor(toRow: statusRow, column: 1)
//        print("│", terminator: "")
//       TerminalState.moveCursor(toRow: statusRow, column: totalWidth)
//        print("│", terminator: "")
//        
//        for r in (row + 2)..<bottomRow {
//           TerminalState.moveCursor(toRow: r, column: 1)
//            print("│", terminator: "")
//           TerminalState.moveCursor(toRow: r, column: colDivider)
//            print("│", terminator: "")
//           TerminalState.moveCursor(toRow: r, column: totalWidth)
//            print("│", terminator: "")
//        }
//        
//        // 3. ├──┬──┤ under status
//       TerminalState.moveCursor(toRow: nextTopRow, column: 1)
//        print("├", terminator: "")
//        for col in 2..<colDivider {
//           TerminalState.moveCursor(toRow: nextTopRow, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: nextTopRow, column: colDivider)
//        print("┬", terminator: "")
//        for col in (colDivider + 1)..<totalWidth {
//           TerminalState.moveCursor(toRow: nextTopRow, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: nextTopRow, column: totalWidth)
//        print("┤", terminator: "")
//        
//        // 4. ├──┼──┤ under next
//       TerminalState.moveCursor(toRow: nextBottomRow, column: 1)
//        print("├", terminator: "")
//        for col in 2..<colDivider {
//           TerminalState.moveCursor(toRow: nextBottomRow, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: nextBottomRow, column: colDivider)
//        print("┼", terminator: "")
//        for col in (colDivider + 1)..<totalWidth {
//           TerminalState.moveCursor(toRow: nextBottomRow, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: nextBottomRow, column: totalWidth)
//        print("┤", terminator: "")
//        
//        // 5. Bottom └──┴──┘
//       TerminalState.moveCursor(toRow: bottomRow, column: 1)
//        print("└", terminator: "")
//        for col in 2..<colDivider {
//           TerminalState.moveCursor(toRow: bottomRow, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: bottomRow, column: colDivider)
//        print("┴", terminator: "")
//        for col in (colDivider + 1)..<totalWidth {
//           TerminalState.moveCursor(toRow: bottomRow, column: col)
//            print("─", terminator: "")
//        }
//       TerminalState.moveCursor(toRow: bottomRow, column: totalWidth)
//        print("┘", terminator: "")
//    }
//    
//    // 2. Status Pane
//    func renderStatusPane(at row: Int) {
//        let contentWidth = TerminalState.terminalWidth - 2
//       TerminalState.moveCursor(toRow: row, column: 2)
//        print(String(repeating: " ", count: contentWidth), terminator: "")
//    }
//    
//    // 3. Next Pane
//    func renderNextPane(at row: Int, historyWidth: Int, ecWidth: Int) {
//        let meta = currentMetadata
//        let isNull = String(describing: meta.name) == "NULL"
//        
//        let formatted = formatEntityNameAndSnippet(
//            name: String(describing: meta.name),
//            snippet: meta.sourceSnippet,
//            context: .next(isNullMetadata: isNull)
//        )
//        
//        let truncated = truncateWithANSI(formatted, to: historyWidth)
//            .padding(to: historyWidth, ansiSafe: true)
//        
//       TerminalState.moveCursor(toRow: row + 1, column: 2)
//        print(truncated, terminator: "")
//    }
//    
//    // 4. History Pane (left column)
//    func renderHistoryPane(at topRow: Int, height: Int, totalWidth: Int, title: String? = nil) {
//        let dividerWidth = 1
//        let outputWidth = (totalWidth - dividerWidth) / 2
//        let historyWidth = totalWidth - outputWidth - dividerWidth
//        let divider = "\(ANSI.gray)│\(ANSI.reset)"
//        let leftColumn = 2 + historyVerticalScrollOffset
//        let rightColumn = 3 + historyWidth
//        let dividerColumn = 2
//        // Reserve space for title if present
//        let contentTopRow = title == nil ? topRow : topRow + 2
//        let visibleHeight = height - (title == nil ? 0 : 2)
//        
//        if let title = title {
//            // Title line
//            let paddedTitle = title.padding(to: historyWidth, ansiSafe: true)
//           TerminalState.moveCursor(toRow: topRow, column: leftColumn)
//            print(paddedTitle, terminator: "")
//            
//            // Underline that extends fully and joins the divider
//           TerminalState.moveCursor(toRow: topRow + 1, column: leftColumn - 1)
//            print("├", terminator: "")
//            print(String(repeating: "─", count: historyWidth * 2 + 1), terminator: "")
//            print("┤", terminator: "")
//            
//            // Draw the joining bar into the divider column
//           TerminalState.moveCursor(toRow: topRow + 1, column: leftColumn + historyWidth)
//            print("┬", terminator: "")
//        }
//        
//        let start = max(0, historyRenderRows.count - height)
//        let end = min(historyRenderRows.count, start + height)
//        let rows = historyRenderRows[start..<end]
//        
//        for (i, row) in rows.enumerated() {
//            let y = contentTopRow + i
//            let rawLeft = row.left ?? ""
//            let rawRight = row.right ?? ""
//            
//            let skippedLeft = rawLeft.skipVisibleCharacters(historyHorizontalScrollOffset)
//            let skippedRight = rawRight.skipVisibleCharacters(historyHorizontalScrollOffset)
//            
//            let left = skippedLeft.prefixVisibleCharacters(historyWidth, ellipsis: "…")
//            let right = skippedRight.prefixVisibleCharacters(historyWidth, ellipsis: "…")
//            
//            // Highlighting logic omitted for brevity, but include as needed
//           TerminalState.moveCursor(toRow: y, column: leftColumn)
//            
//            print(left, terminator: "")
//            
//           TerminalState.moveCursor(toRow: y, column: dividerColumn + historyWidth)
//            print(divider, terminator: "")
//            
//           TerminalState.moveCursor(toRow: y, column: rightColumn)
//            print(right, terminator: "")
//        }
//        
//        // Clear remaining space
//        if visibleHeight > rows.count {
//            for i in rows.count..<visibleHeight {
//                let y = contentTopRow + i
//               TerminalState.moveCursor(toRow: y, column: 2)
//                print(String(repeating: " ", count: historyWidth), terminator: "")
//               TerminalState.moveCursor(toRow: y, column: 2 + historyWidth)
//                print(divider, terminator: "")
//               TerminalState.moveCursor(toRow: y, column: rightColumn)
//                print(String(repeating: " ", count: outputWidth), terminator: "")
//            }
//        }
//    }
//    
//    func oldRenderHistoryPane(at topRow: Int, height: Int, totalWidth: Int) {
//        let dividerWidth = 1
//        let ecWidth = (totalWidth - dividerWidth) / 2
//        let historyWidth = totalWidth - ecWidth - dividerWidth
//        
//        let divider = "\(ANSI.gray)│\(ANSI.reset)"
//        
//        let start = max(0, historyRenderRows.count - height - historyHorizontalScrollOffset)
//        let end = min(historyRenderRows.count, start + height)
//        let rows = historyRenderRows[start..<end]
//        
//        
//        for (i, row) in rows.enumerated() {
//            let y = topRow + i
//            let rawLeft = row.left ?? ""
//            let rawRight = row.right ?? ""
//            
//            let left = truncateWithANSI(rawLeft, to: historyWidth).padding(to: historyWidth, ansiSafe: true)
//            let right = truncateWithANSI(rawRight, to: ecWidth).padding(to: ecWidth, ansiSafe: true)
//            
//            // Check if this is the first line of a step
//            let isFirstLineOfStep = row.left != nil
//            let isInSelectedStep = row.stepIndex == historySelection
//            let isHighlighted = highlightedStepIds.contains(stepResults[row.stepIndex].id)
//            
//            let style: (String) -> String = {
//                if isFirstLineOfStep && isInSelectedStep {
//                    return { "\(ANSI.invert)\($0)\(ANSI.reset)" }
//                } else if isInSelectedStep {
//                    return { "\(ANSI.lightBackground)\($0)\(ANSI.reset)" }
//                } else {
//                    return { $0 }
//                }
//            }()
//            
//            // Left column
//           TerminalState.moveCursor(toRow: y, column: 2)
//            
//            let styledLeft: String
//            if isHighlighted {
//                let strippedLeft = left.strippingANSI
//                styledLeft = "\(ANSI.celadonBackground)\(strippedLeft)\(ANSI.reset)"
//            } else {
//                styledLeft = style(left)
//            }
//            print(styledLeft, terminator: "")
//            
//            // Divider
//           TerminalState.moveCursor(toRow: y, column: 2 + historyWidth)
//            print(divider, terminator: "")
//            
//            // Right column
//           TerminalState.moveCursor(toRow: y, column: 3 + historyWidth)
//            let styledRight = isHighlighted ? "\(ANSI.celadonBackground)\(ANSI.black)\(right)\(ANSI.reset)" : style(right)
//            print(right, terminator: "")
//            
//        }
//        
//        // Clear remaining space
//        for i in rows.count..<height {
//            let y = topRow + i
//           TerminalState.moveCursor(toRow: y, column: 2)
//            print(String(repeating: " ", count: historyWidth), terminator: "")
//           TerminalState.moveCursor(toRow: y, column: 2 + historyWidth)
//            print(divider, terminator: "")
//           TerminalState.moveCursor(toRow: y, column: 3 + historyWidth)
//            print(String(repeating: " ", count: ecWidth), terminator: "")
//        }
//    }
//    
//    // 5. Execution Context Pane (right column)
//    func renderECPane(at row: Int, height: Int, width: Int) {
//        let startCol = TerminalState.terminalWidth - width + 1
//        
//        // Title
//       TerminalState.moveCursor(toRow: row + 1, column: startCol)
//        print("Execution Context", terminator: "")
//        
//        // Keys (sorted and converted to String)
//        
//        let step: StepResult
//        if let selection = historySelection {
//            step = stepResults[selection]
//        } else {
//            guard let rawStep = stepResults.last else { return }
//            step = rawStep
//        }
//        
//        let summaries = step.executionContextSnapshot.variables
//        let keys = summaries.keys.sorted()
//        
//        let maxLabelWidth = keys.map(\.count).max() ?? 0
//        let contextStartRow = row + 3
//        let maxVisible = height - 3
//        
//        for (index, key) in keys.prefix(maxVisible).enumerated() {
//            let y = contextStartRow + index
//            guard y < row + height else { break }
//            
//            let label = key.padding(toLength: maxLabelWidth, withPad: " ", startingAt: 0)
//            let rawValue = String(describing: summaries[key]?.value ?? "")
//                .replacingOccurrences(of: "\n", with: " ")
//            
//            let fullLine = "\(label) = \(rawValue)"
//            let truncated = truncateWithANSI(fullLine, to: width)
//            let padded = truncated.padding(to: width, ansiSafe: true)
//            
//           TerminalState.moveCursor(toRow: y, column: startCol)
//            print(padded, terminator: "")
//        }
//        
//        // Clear remaining lines
//        for i in keys.count..<maxVisible {
//            let y = contextStartRow + i
//           TerminalState.moveCursor(toRow: y, column: startCol)
//            print(String(repeating: " ", count: width), terminator: "")
//        }
//    }
//    
//    func renderCommandPrompt(at row: Int) {
//        let prompt = "[n] step   [c] capture   [space] pause   [r] reset   [q] quit"
//        let padded = prompt.padding(to: TerminalState.terminalWidth, ansiSafe: true)
//       TerminalState.moveCursor(toRow: row, column: 1)
//        print(padded)
//    }
//    
//    func renderHistoryPaneSelection(at row: Int, height: Int, historyWidth: Int) {
//        let left = 1
//        let right = historyWidth + 2
//        
//        // Top border
//       TerminalState.moveCursor(toRow: row, column: left)
//        print("\(ANSI.borderSelection)╔" + String(repeating: "═", count: historyWidth) + "╗", terminator: "")
//        
//        // Vertical sides
//        for i in 1..<height {
//           TerminalState.moveCursor(toRow: row + i, column: left)
//            print("║", terminator: "")
//           TerminalState.moveCursor(toRow: row + i, column: right)
//            print("║", terminator: "")
//        }
//        
//        // Bottom border
//       TerminalState.moveCursor(toRow: row + height, column: left)
//        print("╚" + String(repeating: "═", count: historyWidth) + "╝\(ANSI.reset)", terminator: "")
//    }
//    
//    func renderLintSubPaneSelection(at row: Int, height: Int, width: Int) {
//        let left = 1
//        let right = left + width + 1
//        
//        // Top border
//       TerminalState.moveCursor(toRow: row + 2, column: left)
//        print("\(ANSI.borderSelection)╔" + String(repeating: "═", count: width) + "╗\(ANSI.reset)", terminator: "")
//        
//        // Middle rows
//        for i in 1..<height - 2 {
//           TerminalState.moveCursor(toRow: row + 2 + i, column: left)
//            print("\(ANSI.borderSelection)║", terminator: "")
//           TerminalState.moveCursor(toRow: row + 2 + i, column: right)
//            print("║\(ANSI.reset)", terminator: "")
//        }
//        
//        // Bottom border
//       TerminalState.moveCursor(toRow: row + height, column: left)
//        print("\(ANSI.borderSelection)╚" + String(repeating: "═", count: width) + "╝\(ANSI.reset)", terminator: "")
//    }
//    
//    func renderOutputSubPaneSelection(at row: Int, height: Int, width: Int) {
//        let left = width + 2
//        let right = left + width + 1
//        
//        // Top border
//       TerminalState.moveCursor(toRow: row + 2, column: left)
//        print("\(ANSI.borderSelection)╔" + String(repeating: "═", count: width) + "╗\(ANSI.reset)", terminator: "")
//        
//        // Middle rows
//        for i in 1..<height - 2 {
//           TerminalState.moveCursor(toRow: row + 2 + i, column: left)
//            print("\(ANSI.borderSelection)║", terminator: "")
//           TerminalState.moveCursor(toRow: row + 2 + i, column: right)
//            print("║\(ANSI.reset)", terminator: "")
//        }
//        
//        // Bottom border
//       TerminalState.moveCursor(toRow: row + height, column: left)
//        print("\(ANSI.borderSelection)╚" + String(repeating: "═", count: width))
//    }
//    
//    
//    func renderECPaneSelection(at row: Int, height: Int, ecWidth: Int) {
//        let totalWidth = TerminalState.terminalWidth
//        let left = totalWidth - ecWidth - 1
//        let right = totalWidth
//        
//        // Top border
//       TerminalState.moveCursor(toRow: row, column: left)
//        print("\(ANSI.borderSelection)╔" + String(repeating: "═", count: ecWidth) + "╗", terminator: "")
//        
//        // Vertical borders
//        for i in 1..<height {
//           TerminalState.moveCursor(toRow: row + i, column: left)
//            print("║", terminator: "")
//           TerminalState.moveCursor(toRow: row + i, column: right)
//            print("║", terminator: "")
//        }
//        
//        // Bottom border
//       TerminalState.moveCursor(toRow: row + height, column: left)
//        print("╚" + String(repeating: "═", count: ecWidth) + "╝\(ANSI.reset)", terminator: "")
//    }
//    
//    func renderNextPaneSelection(at row: Int, width: Int) {
//        let left = 1
//        let right = width + 2
//        
//       TerminalState.moveCursor(toRow: row, column: left)
//        print("\(ANSI.borderSelection)╔" + String(repeating: "═", count: right - 2) + "╗", terminator: "")
//        
//       TerminalState.moveCursor(toRow: row + 1, column: left)
//        print("║", terminator: "")
//       TerminalState.moveCursor(toRow: row + 1, column: right)
//        print("║", terminator: "")
//        
//       TerminalState.moveCursor(toRow: row + 2, column: left)
//        print("╚" + String(repeating: "═", count: right - 2) + "╝\(ANSI.reset)", terminator: "")
//    }
//    
//    func render() {
//        // 1. Clear the screen and home the cursor
//        print("\u{001B}[2J\u{001B}[H", terminator: "")
//        
//        // 2. Calculate layout dimensions
//        let termWidth = TerminalState.terminalWidth
//        let termHeight = TerminalState.terminalHeight
//        let ecWidth = termWidth / 3
//        let historyWidth = termWidth - ecWidth - 3 // 3: middle bar + borders
//        let bodyHeight = termHeight - 9 // title + status + next (3 lines) + bottom + cmd
//        
//        // 3. Cursor-aligned rendering
//        var row = 1
//        var rows: Int
//        var columns: Int
//        
//        (rows,columns) = statusPane.render(at: row, left: 2, width: termWidth - 2); row += rows
//        
//        let nextPaneRow = row
//        (rows,columns) = nextLintPane.render(at: row, left: 2, width: termWidth - 2); row += rows
//        
//        let ecPaneRow = row
//        executionContextPane.render(at: row, height: bodyHeight, left: ???, width: ecWidth); row += rows
//        
//        row += 3
//        let historyRow = row
//        historyPane.render(at: row, height: bodyHeight, left: ???, width: historyWidth, title: "Lint History");
//        
//        (row, columns) = commandLinePane.render(at: row, width: ecWidth)
//        
//        renderBorders(at: 1, bodyHeight: bodyHeight, historyWidth: historyWidth, ecWidth: ecWidth)
//    }
//}
//    
////    func render() {
////        // Clamp selection first
////
////        if let selection = historySelection {
////            if selection >= stepResults.count {
////                historySelection = stepResults.count - 1
////            }
////
////            if selection < 0 {
////                historySelection = 0
////            }
////        }
////
////        // 1. Clear the screen and home the cursor
////        print("\u{001B}[2J\u{001B}[H", terminator: "")
////
////        // 2. Calculate layout dimensions
////        let termWidth = TerminalState.terminalWidth
////        let termHeight = TerminalState.terminalHeight
////        let ecWidth = termWidth / 3
////        let historyWidth = termWidth - ecWidth - 3 // 3: middle bar + borders
////        let bodyHeight = termHeight - 9 // title + status + next (3 lines) + bottom + cmd
////
////        // 3. Cursor-aligned rendering
////        var row = 1
////        renderStatusPane(at: row); row += 2
////
////        let nextPaneRow = row
////        renderNextPane(at: row, historyWidth: historyWidth, ecWidth: ecWidth);
////
////        let ecPaneRow = row
////        renderECPane(at: row, height: bodyHeight, width: ecWidth)
////        row += 3
////        let historyRow = row
////        renderHistoryPane(at: row, height: bodyHeight, totalWidth: historyWidth, title: "Lint History")
////
////        row += bodyHeight
////        renderBorders(at: 1, bodyHeight: bodyHeight, historyWidth: historyWidth, ecWidth: ecWidth); row += 1
////
////        switch paneSelection {
////        case .history:
////            renderHistoryPaneSelection(at: historyRow - 1, height: bodyHeight + 1, historyWidth: historyWidth)
////        case .lint:
////            renderLintSubPaneSelection(at: historyRow - 1, height: bodyHeight + 1, width: historyWidth / 2)
////        case .output:
////            renderOutputSubPaneSelection(at: historyRow - 1, height: bodyHeight + 1, width: historyWidth / 2)
////        case .ec:
////            renderECPaneSelection(at: ecPaneRow, height: bodyHeight + 3, ecWidth: ecWidth)
////        case .next:
////            renderNextPaneSelection(at: nextPaneRow, width: historyWidth)
////        default:
////            break
////        }
////        row += 1
////        renderCommandPrompt(at: row)
////    }
////}
//#endif
