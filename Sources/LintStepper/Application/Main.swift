//
//  main.swift.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/12/25.
//

import Foundation
import MultitaskingEngine

nonisolated(unsafe) var needRender = true

enum OutputContext {
    case next(isNullMetadata: Bool)
    case history
    case capture
}

enum Command {
    // Application
    case quit
    case escape

    // Debugger
    case step
    case bigStep
    case reset
    case capture
    case pause
    
    // Presentation
    case forwardSwitchPane
    case reverseSwitchPane
    case forwardSwtichSubPane
    case reverseSwitchSubPane
    case scrollLeft
    case scrollRight
    case scrollUp
    case scrollDown
    case scrollToTop
    case scrollToBottom
    case setLineScrollMode
    case setStepScrollMode
    case setTickScrollMode
    case setPageScrollMode
    
    // General
    case nop

}

@main
struct LintStepperMain {
    static func main() async {
        let blueprint = Comprehension_S_ULangParser()
        let context = blueprint.context
        let specifier = LintSpecifier({ _ in context.ensure("input", defaultValue: "ULangParser = => subscription {\n     from emit line ->\n     emit character ->\n     identify_symbols ->\n     collect groups ->\n     detect delimiters ->\n     convert groups into tokens ->\n     build ast.\n }"); return .running }, role: "Table preinitialization", uLangEntityID: ULangEntityID("Comprehension_S_ULangParser"))
        let instance = blueprint.instantiate(preinitialization_specifier: specifier, executionContext: nil )
        let runner = DebuggerLintRunner(provider: instance)
                
        let debugger = LintDebugger(runner: runner, context: context)
        
        let ui = TextUI()
        let uiController = UIStateController(debugger: debugger, context: context, ui: ui)
        
        var running = true
        
        signal(SIGWINCH) { _ in
            needRender = true
        }
        
        ui.initialize()
        defer { ui.shutdown() }
        
        TerminalState.setRawMode()
        
        atexit {
            TerminalState.restoreMode()
        }
        
        while running {
            uiController.renderIfNeeded()
            
            let command = await ui.handleInput()
           
            switch command {
            case .quit:
                running = false
            case .nop:
                break
            case .step:
                await debugger.step()
            case .reset:
                debugger.reset()
                ui.reset()
                uiController.reset()
            case .capture:
                await debugger.startCapture(interval: 100)
            case .pause:
                pause = !pause
                
            default:
                await uiController.handleCommand(command)
            }
        }
        
        print("\nExiting lint_stepper.")
    }
}
