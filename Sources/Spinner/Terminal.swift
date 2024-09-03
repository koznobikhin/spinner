//
//  File.swift
//  
//
//  Created by Konstantin Oznobikhin on 04.09.2024.
//

enum Terminal {
    static let ESC = "\u{001B}"

    static func CSI(_ code: String) -> String {
        "\(ESC)[\(code)"
    }

    static func eraseInLine(_ value: Int) -> String {
        CSI("\(value)K")
    }

    static func eraseToEnd() -> String {
        eraseInLine(0)
    }

    static func eraseToBeginning() -> String {
        eraseInLine(1)
    }

    static func eraseLine() -> String {
        eraseInLine(2)
    }

    enum Cursor {
        static let hide = CSI("?25l")
        static let show = CSI("?25h")

        static func horizontalAbsolute(_ value: Int) -> String {
            let value = max(1, value)
            return CSI("\(value)G")
        }
    }
}
