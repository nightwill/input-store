import Foundation

public struct InputEvent {
    public let player: Int
    public let button: InputButton
    public let pressed: Bool
    public let value: Double?

    init(player: Int, button: InputButton, pressed: Bool) {
        self.player = player
        self.button = button
        self.pressed = pressed
        self.value = nil
    }

    init(player: Int, button: InputButton, pressed: Bool, value: Double) {
        self.player = player
        self.button = button
        self.pressed = pressed
        self.value = value
    }
}
