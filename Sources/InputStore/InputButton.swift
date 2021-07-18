import Foundation

public enum InputButton: Int, Codable {
    case up
    case down
    case left
    case right

    /// A or Cross
    case a
    /// B or Circle
    case b
    case c
    /// X or Square
    case x
    /// Y or Triangle
    case y
    case z

    case l1
    case l2
    case l3
    case r1
    case r2
    case r3
    case start
    case select
    case analogMode
    case leftAnalogUp
    case leftAnalogDown
    case leftAnalogLeft
    case leftAnalogRight
    case rightAnalogUp
    case rightAnalogDown
    case rightAnalogLeft
    case rightAnalogRight
    case menu
}
