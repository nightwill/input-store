import Foundation

typealias KeyboardMap = [UInt16: InputButton]

extension KeyboardMap {

    static var `default`: KeyboardMap {
        [
            0: .left,
            2: .right,
            13: .up,
            1: .down,
            35: .a,
            33: .b,
            30: .c,
            41: .x,
            39: .y,
            42: .z,
            18: .select,
            19: .start,
            36: .a,
            53: .menu,
        ]
    }

    static var empty: KeyboardMap {
        [:]
    }
    
}
