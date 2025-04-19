//
//  terminal_state.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/12/25.

import Foundation
import Darwin
import PosixCompat

enum KeyInput {
    case character(Character)
    
    // Arrow keys
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    
    case shiftArrowUp
    case shiftArrowDown
    case shiftArrowLeft
    case shiftArrowRight
    
    case optionArrowUp
    case optionArrowDown
    case optionArrowLeft
    case optionArrowRight
    
    // Navigation
    case home
    case end
    case pageUp
    case pageDown
    
    case shiftHome
    case shiftEnd
    case shiftPageUp
    case shiftPageDown
    
    // Control Keys
    case enter
    case escape
    case tab
    case shiftTab
    case backspace
    case delete
    case space
    
    // Capture and Break
    case commandPeriod     // CMD+.
    case ctrlC             // Interrupt signal
    
    // Function keys
    case functionKey(Int)  // F1–F12 and beyond (F13+)
    
    // Unknown or unhandled
    case unknown(String)
}

enum TerminalState {
    nonisolated(unsafe) private static var originalTerm = termios()
    
    static var isXcode: Bool {
        return ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("Xcode") == true
    }
    
    static var terminalWidth: Int {
        getTerminalSize().width
    }
    
    static var terminalHeight: Int {
        getTerminalSize().height
    }
    
    private static func getTerminalSize() -> (width: Int, height: Int) {
        let defaultWidth = 100
        let defaultHeight = 40
        
        guard isatty(STDOUT_FILENO) != 0 else {
            return (defaultWidth, defaultHeight)
        }
        
        var size = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0 {
            let width = Int(size.ws_col)
            let height = Int(size.ws_row)
            
            // Fallback if terminal returns 0
            return (
                width > 0 ? width : defaultWidth,
                height > 0 ? height : defaultHeight
            )
        }
        
        return (defaultWidth, defaultHeight)
    }
    
    static var contentWidth: Int {
        terminalWidth - 2 // accounts for the ││ or ║║ border
    }
    
    static func setRawMode() {
        tcgetattr(STDIN_FILENO, &originalTerm)
        var raw = originalTerm
        raw.c_lflag &= ~(UInt(ECHO | ICANON))
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)
    }
    
    static func restoreMode() {
        tcsetattr(STDIN_FILENO, TCSANOW, &originalTerm)
    }
    
    static func moveCursor(toRow row: Int, column: Int) {
        print("\u{001B}[\(row);\(column)H", terminator: "")
    }
    
    static func hideCursor() {
        print("\u{001B}[?25l", terminator: "")
    }

    static func showCursor() {
        print("\u{001B}[?25h", terminator: "")
    }

    static func saveCursor() {
        print("\u{001B}[s", terminator: "")
    }
    
    static func restoreCursor() {
        print("\u{001B}[u", terminator: "")
    }
    
    static func readKey() -> String {
        setRawMode()
        defer { restoreMode() }
        
        var buffer = [UInt8](repeating: 0, count: 1)
        read(STDIN_FILENO, &buffer, 1)
        return String(bytes: buffer, encoding: .utf8) ?? ""
    }
    
    @discardableResult
    static func waitForKeyOrTimeout(milliseconds: Int32 = 250) -> Bool {
        var fds = fd_set()
        swift_fd_zero(&fds)
        swift_fd_set(STDIN_FILENO, &fds)
        
        var timeout = timeval(
            tv_sec: 0,
            tv_usec: milliseconds * 1000
        )
        
        return select(STDIN_FILENO + 1, &fds, nil, nil, &timeout) > 0
    }
    
    static func readKeyInput() -> KeyInput? {
        var buffer: [UInt8] = [0, 0, 0, 0, 0, 0]
        let readCount = read(STDIN_FILENO, &buffer, buffer.count)
        
        guard readCount > 0 else { return nil }
        
        switch buffer[0] {
        case 3:
            return .ctrlC // Ctrl+C (interrupt)
            
        case 9:
            return .tab
            
        case 10, 13:
            return .enter
            
        case 27: // ESC
            if buffer[1] == 0 {
                return .escape
            } else if buffer[1] == 91 { // CSI
                switch buffer[2] {
                case 65: return .arrowUp
                case 66: return .arrowDown
                case 67: return .arrowRight
                case 68: return .arrowLeft
                case 90: return .shiftTab
                    
                case 49 where buffer[3] == 59 && buffer[4] == 50: // ESC [1;2X
                    switch buffer[5] {
                    case 65: return .shiftArrowUp
                    case 66: return .shiftArrowDown
                    case 67: return .shiftArrowRight
                    case 68: return .shiftArrowLeft
                    default: break
                    }
                    
                case 49 where buffer[3] == 59 && buffer[4] == 51: // ESC [1;2X
                    switch buffer[5] {
                    case 65: return .optionArrowUp
                    case 66: return .optionArrowDown
                    case 67: return .optionArrowRight
                    case 68: return .optionArrowLeft
                    default: break
                    }
                    
                case 51 where buffer[3] == 126:
                    return .delete
                    
                case 53 where buffer[3] == 126:
                    return .pageUp
                case 54 where buffer[3] == 126:
                    return .pageDown
                    
                default:
                    break
                }
            }
            return .unknown(String(bytes: buffer.prefix(readCount), encoding: .utf8) ?? "<ESC>")
        case 123: return .character("{")
        case 125: return .character("}")
        case 127:
            return .backspace
            
        default:
            return .character(Character(UnicodeScalar(buffer[0])))
        }
    }
    
    static func installInterruptHandler() {
        signal(SIGINT) { _ in
            shouldStopCapture = true
        }
    }
    
    public static func promptForNumber(prompt: String="", default defaultValue: Int = 5) async -> Int? {
        var input = ""
        
        TerminalState.saveCursor()
        TerminalState.hideCursor()
        
        let dialogRow = TerminalState.terminalHeight / 2
        let dialogColumn = (TerminalState.terminalWidth - 30) / 2
        
        func draw() {
            TerminalState.moveCursor(toRow: dialogRow, column: dialogColumn)
            print("\u{001B}[48;5;237m\u{001B}[30m \(prompt) \(input.padding(toLength: 4, withPad: "_", startingAt: 0)) \u{001B}[0m", terminator: "")
            fflush(stdout)
        }
        
        draw()
        
        while true {
            guard let key = TerminalState.readKeyInput() else { continue }
            
            switch key {
            case .character(let char) where char.isWholeNumber && input.count < 4:
                input.append(char)
                draw()
                
            case .enter:
                TerminalState.restoreCursor()
                TerminalState.showCursor()
                return Int(input)
                
            case .escape:
                TerminalState.restoreCursor()
                TerminalState.showCursor()
                return nil
                
            case .backspace:
                if !input.isEmpty {
                    input.removeLast()
                    draw()
                }
                
            default:
                continue
            }
        }
    }
    
}

func truncateWithANSI(_ string: String, to visibleLimit: Int) -> String {
    if TerminalState.isXcode {
        return String(string.prefix(visibleLimit))
    }
    
    let ansiPattern = /\u{001B}\[[0-9;]*m/
    
    var result = ""
    var visibleCount = 0
    var index = string.startIndex
    
    while index < string.endIndex && visibleCount < visibleLimit - 1 {
        if let match = string[index...].firstMatch(of: ansiPattern) {
            let range = match.range
            
            if range.lowerBound == index {
                result += String(string[range])
                index = range.upperBound
                continue
            }
        }
        
        result.append(string[index])
        visibleCount += 1
        index = string.index(after: index)
    }
    
    if index < string.endIndex {
        result += "…"
        if !result.hasSuffix(ANSI.reset) {
            result += ANSI.reset
        }
    }
    
    return result
}
