//
//  render_rows.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/14/25.
//

protocol RenderRow: AnyObject {
    var stepIndex: Int { get }
    var tick: Int      { get }
}

class TickRenderRow: RenderRow {
    let tick: Int
    let stepIndex: Int
    
    init(tick: Int, stepIndex: Int) {
        self.tick = tick
        self.stepIndex = stepIndex
    }
}

class StepRenderRow: RenderRow {
    let stepIndex: Int
    let tick: Int
    let left: String?
    let right: String?

    init(stepIndex: Int, tick: Int, left: String?, right: String?) {
        self.stepIndex = stepIndex
        self.tick = tick
        self.left = left
        self.right = right
    }
}

protocol RenderRowProvider {
    var renderRows: [RenderRow] { get }
}

