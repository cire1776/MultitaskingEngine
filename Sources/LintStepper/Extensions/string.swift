//
//  string.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/13/25.
//

import Foundation

extension String {
    var strippingANSI: String {
        self.replacingOccurrences(of: #"\x1B\[[0-9;]*m"#, with: "", options: .regularExpression)
    }
    
    var ansiCount: Int {
        let pattern = #"\u{001B}\[[0-9;]*m"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return 0
        }
        
        let nsrange = NSRange(self.startIndex..<self.endIndex, in: self)
        let matches = regex.matches(in: self, options: [], range: nsrange)
        
        return matches.reduce(0) { total, match in
            total + match.range.length
        }
    }
    
    func suffixSkippingANSI(visibleCount: Int) -> String {
        let ansiRegex: Regex<Substring> = #/\u{001B}\[[0-9;]*m/#
        let matches = self.matches(of: ansiRegex)
        
        var output = ""
        var visible = 0
        var index = self.endIndex
        
        while visible < visibleCount && index > self.startIndex {
            let prev = self.index(before: index)
            
            // Check if an ANSI sequence ends at this index
            if let match = matches.last(where: { $0.range.upperBound == index }) {
                output = self[match.range] + output
                index = match.range.lowerBound
                continue
            }
            
            output = String(self[prev]) + output
            index = prev
            visible += 1
        }
        
        if !output.hasSuffix(ANSI.reset) {
            output += ANSI.reset
        }
        
        return output
    }
    
    func skipVisibleCharacters(_ visibleCountToSkip: Int) -> String {
        let ansiRegex = #/\u{001B}\[[0-9;]*m/#
        var visibleSkipped = 0
        var result = ""
        var index = startIndex
        
        // Move index to the point where visibleCountToSkip characters are passed
        while index < endIndex && visibleSkipped < visibleCountToSkip {
            if let match = self[index...].firstMatch(of: ansiRegex),
               match.range.lowerBound == index {
                // Append ANSI sequence
                result += String(self[match.range])
                index = match.range.upperBound
            } else {
                // Skip visible character
                index = self.index(after: index)
                visibleSkipped += 1
            }
        }
        
        // Append the rest of the string (visible + ANSI)
        result += self[index...]
        
        return result
    }
    
//    func suffixVisibleCharacters(_ visibleCount: Int) -> String {
//        let ansiRegex = #/\u{001B}\[[0-9;]*m/#
//        var result = ""
//        var visibleCollected = 0
//        var collected = [(char: Character?, ansi: String?)]()
//        
//        var index = self.index(before: endIndex)
//        
//        while index >= startIndex && visibleCollected < visibleCount {
//            if let match = self[index...].firstMatch(of: ansiRegex),
//               match.range.lowerBound == index {
//                collected.append((char: nil, ansi: String(self[match.range])))
//                if index > startIndex {
//                    index = self.index(index, offsetBy: match.range.count)
//                } else {
//                    break
//                }
//            } else {
//                collected.append((char: self[index], ansi: nil))
//                visibleCollected += 1
//                if index > startIndex {
//                    index = self.index(before: index)
//                } else {
//                    break
//                }
//            }
//        }
//        
//        // Because we built this backwards, reverse it and assemble the result
//        for part in collected.reversed() {
//            if let ansi = part.ansi {
//                result.append(ansi)
//            } else if let char = part.char {
//                result.append(char)
//            }
//        }
//        
//        return result
//    }
    
    func prefixVisibleCharacters(_ visibleCount: Int, ellipsis: String? = nil) -> String {
        let ansiRegex = #/\u{001B}\[[0-9;]*m/#
        var visibleAdded = 0
        var result = ""
        var index = startIndex
        var trailingANSI = ""

        let ellipsisWidth = ellipsis?.strippingANSI.count ?? 0
        let maxVisible = visibleCount - ellipsisWidth

        // Phase 1: Collect up to maxVisible visible characters
        while index < endIndex && visibleAdded < maxVisible {
            if let match = self[index...].firstMatch(of: ansiRegex),
               match.range.lowerBound == index {
                result += String(self[match.range])
                index = match.range.upperBound
            } else {
                result.append(self[index])
                visibleAdded += 1
                index = self.index(after: index)
            }
        }

        // Phase 2: Preserve trailing ANSI codes
        while index < endIndex {
            if let match = self[index...].firstMatch(of: ansiRegex),
               match.range.lowerBound == index {
                trailingANSI += String(self[match.range])
                index = match.range.upperBound
            } else {
                break // Stop if we hit visible characters again
            }
        }

        // Combine final result
        if visibleAdded == maxVisible, let ellipsis = ellipsis {
            result += ellipsis
        }

        return result + trailingANSI
    }
    
    func padding(to targetLength: Int, centered: Bool=false, ansiSafe: Bool) -> String {
        guard ansiSafe else {
            return self.padding(toLength: targetLength, withPad: " ", startingAt: 0)
        }
        
        let visible = self.strippingANSI
        let paddingCount = max(0, targetLength - visible.count)
        
        let leftPadding = centered ? paddingCount / 2 : 0
        let rightPadding = paddingCount - leftPadding
        
        return String(repeating: " ", count: leftPadding) + self + String(repeating: " ", count: rightPadding)
    }
}
