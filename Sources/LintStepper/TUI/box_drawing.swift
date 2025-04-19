enum BoxDrawing: String {
    case doubleHorizontal = "═" // U+2550
    case doubleVertical = "║"   // U+2551

    case doubleTopLeft = "╔"    // U+2554
    case doubleTopRight = "╗"   // U+2557
    case doubleBottomLeft = "╚" // U+255A
    case doubleBottomRight = "╝"// U+255D

    case doubleVerticalAndRight = "╠"   // U+2560
    case doubleVerticalAndLeft = "╣"    // U+2563
    case doubleHorizontalAndDown = "╦"  // U+2566
    case doubleHorizontalAndUp = "╩"    // U+2569
    case doubleVerticalAndHorizontal = "╬" // U+256C

    // Single-line equivalents
    case singleHorizontal = "─" // U+2500
    case singleVertical = "│"   // U+2502
    case singleTopLeft = "┌"    // U+250C
    case singleTopRight = "┐"   // U+2510
    case singleBottomLeft = "└" // U+2514
    case singleBottomRight = "┘"// U+2518
    case singleVerticalAndRight = "├"   // U+251C
    case singleVerticalAndLeft = "┤"    // U+2524
    case singleHorizontalAndDown = "┬"  // U+252C
    case singleHorizontalAndUp = "┴"    // U+2534
    case singleVerticalAndHorizontal = "┼" // U+253C

    // Mixed junctions (double vertical, single horizontal)
    case doubleVerticalSingleRight = "╟" // U+255F
    case doubleVerticalSingleLeft = "╢"  // U+2562
    case doubleVerticalSingleHorizontal = "╫" // U+256B

    // Mixed junctions (single vertical, double horizontal)
    case singleVerticalDoubleDown = "╤" // U+2564
    case singleVerticalDoubleUp = "╧"   // U+2567
    case singleVerticalDoubleHorizontal = "╪" // U+256A
}
