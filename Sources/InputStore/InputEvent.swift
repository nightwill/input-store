import Foundation

struct InputEvent {
    let player: Int
    let button: InputButton
    let pressed: Bool
    let value: Double?

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
