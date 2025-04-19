//
//  ANSI.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/15/25.
//


enum ANSI {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let italic = "\u{001B}[3m"
    static let invert = "\u{001B}[7m"
    static let hideCursor = "\u{001B}[?25l"
    static let showCursor = "\u{001B}[?25h"

    static func color(_ code: Int) -> String {
        return "\u{001B}[\(code)m"
    }

    // Common colors
    static let black = color(30)
    static let red = color(31)
    static let green = color(32)
    static let yellow = color(33)
    static let blue = color(34)
    static let magenta = color(35)
    static let cyan = color(36)
    static let white = color(37)
    static let gray = color(90)
    static let teal = "\u{001B}[38;5;37m"
    static let slateBlue = "\u{001B}[38;5;61m"
    static let aloeWash = "\u{001B}[38;2;34;60;48m"    // Very dark green for contrast

    
    // backgrounds
    static let grayBackground = "\u{001B}[48;5;235m"
    static let lightBackground = "\u{001B}[48;5;250m"
    static let veryLightBackground = "\u{001B}[48;5;253m"
    static let mintBackground = "\u{001B}[48;5;120m"
    static let celadonBackground = "\u{001B}[48;5;194m"      // Very light green with yellow tint
    static let paleMintBackground = "\u{001B}[48;5;157m"      // Soft mint
    static let springFrostBackground = "\u{001B}[48;5;151m"   // Subdued green
    static let seafoamBackground = "\u{001B}[48;5;152m"       // Mellow bluish green
    static let avocadoBackground = "\u{001B}[48;5;186m"       // Greenish-tan pastel
    static let aloeWashBackground = "\u{001B}[48;2;224;248;232m" // Soft green, pastel tone

    // Themes
    static let borderSelection = Self.teal
    static let selected = "\(Self.veryLightBackground)\(Self.black)\(Self.bold)"
    static let highlighted = "\(Self.lightBackground)\(Self.gray)"
    static let recent = "\(Self.celadonBackground)\(Self.black)"
    static let recentSelected = "\(Self.celadonBackground)\(Self.black)\(Self.bold)"
}

