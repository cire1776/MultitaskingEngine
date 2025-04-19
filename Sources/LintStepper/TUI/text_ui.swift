//
//  TextUI.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


import Foundation

class TextUI {
    var displayBorders = true

    func initialize() {
        print("\u{1b}[?1049h", terminator: "") // Enter alternate buffer
        print("\u{1b}[?25l", terminator: "")   // Hide cursor
        print("\u{1b}[3J", terminator: "")     // Clear scrollback
        fflush(stdout)
    }
    
    func shutdown() {
        print("\u{1b}[?25h", terminator: "")   // Show cursor
        print("\u{1b}[?1049l", terminator: "") // Exit alternate bufferi
        print("exiting ULang Debugger...")
        fflush(stdout)
    }
    
    func reset() {
        displayBorders = true
    }
    
    func handleInput() async -> Command {
        if TerminalState.waitForKeyOrTimeout(milliseconds: 100) {
            let key = TerminalState.readKeyInput()
            
            guard let key = key else { return .nop }
            
            let command = await handle(key)
            needRender = true
            return command
        }
        return .nop
    }
    
    func handle(_ key: KeyInput) async -> Command {
        switch key {
        case .character("T"):
            displayBorders = !displayBorders
            break
        case .character("q"):
            return .quit
        case .escape, .character("`"):
            return .escape
            
        case .character("n"):
            return .step
        case .character("N"):
            return .bigStep
        case .character("r"):
            return .reset
        case .character("c"):
            return .capture
        case .character(" "):
            return .pause
            
        case .tab:
            return .forwardSwitchPane
        case .shiftTab:
            return .reverseSwitchPane
        case .character("]"):
            return .forwardSwtichSubPane
        case .character("["):
            return .reverseSwitchSubPane
        case .arrowLeft:
            return .scrollLeft
        case .arrowRight:
            return .scrollRight
        case .arrowUp:
            return .scrollUp
        case .arrowDown:
            return .scrollDown
        case .character("<"):
            return .scrollToTop
        case .character(">"):
            return .scrollToBottom
        case .character("1"):
            return .setLineScrollMode
        case .character("2"):
            return .setStepScrollMode
        case .character("3"):
            return .setTickScrollMode
        case .character("4"):
            return .setPageScrollMode

        default:
            break
        }
        
        return .nop
    }
}
