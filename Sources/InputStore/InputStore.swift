import Combine
import Foundation
import GameController

public struct InputHandlerID: Hashable, Equatable {
    fileprivate let id = UUID()

    public init() {

    }
}

public typealias InputEventHandler = (InputEvent) -> Void
public typealias ConnectionEventHandler = (Bool) -> Void

public struct EventTypes: OptionSet {

    public let rawValue: Int8

    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }

    public static let gamepad = EventTypes(rawValue: 1)
    public static let keyboard = EventTypes(rawValue: 1 << 1)

}

public final class InputStore: ObservableObject {

    private struct HandlerEntry {
        let id: InputHandlerID
        let eventTypes: EventTypes?
        var handler: InputEventHandler?
    }

    private var cancellable: Set<AnyCancellable> = []
    private var lastDPadButton: InputButton?
    private var isActiveWindow = true
    private var handlerEntries: [HandlerEntry] = []

    public var p1KeyboardMap: KeyboardMap = .default
    public var p2KeyboardMap: KeyboardMap = .empty

    public var buttonEventHandler: InputEventHandler?
    public var connectionEventHandler: ConnectionEventHandler?

    public init() {
        addControllers()
        addKeyboard()
    }

    public func addButtonHandler(id: InputHandlerID, eventTypes: EventTypes?, handler: @escaping InputEventHandler) {
        handlerEntries.append(.init(id: id, eventTypes: eventTypes, handler: handler))
    }

    public func removeButtonHandler(id: InputHandlerID) {
        if let index = handlerEntries.lastIndex(where: { $0.id == id }) {
            handlerEntries.remove(at: index)
        }
    }

    @discardableResult
    private func send(_ event: InputEvent, eventType: EventTypes) -> Bool {
        guard let currentHandler = handlerEntries.last else {
            print("No handlers")
            return false
        }
        if let types = currentHandler.eventTypes, !types.contains(eventType) {
            print("Current handler doesn't support current event")
            return false
        }
        currentHandler.handler?(event)
        return true
    }

    private func sendGamepad(_ event: InputEvent) {
        send(event, eventType: .gamepad)
    }

    private func sendKeyboard(_ event: InputEvent) -> Bool {
        send(event, eventType: .keyboard)
    }

}

// MARK: - Gamepads
extension InputStore {

    private func sendConnectionEvent(_ event: Bool) {
        connectionEventHandler?(event)
    }

    private func addControllers() {
        NotificationCenter.default
            .publisher(for: NSNotification.Name.GCControllerDidConnect)
            .sink(receiveValue: onControllerConnected)
            .store(in: &cancellable)

        NotificationCenter.default
            .publisher(for: NSNotification.Name.GCControllerDidDisconnect)
            .sink(receiveValue: { _ in self.sendConnectionEvent(false) })
            .store(in: &cancellable)

        NotificationCenter.default.publisher(for: NSNotification.Name.GCControllerDidBecomeCurrent )
            .sink(receiveValue: {
                print("Controller become current",$0)
            })
            .store(in: &cancellable)

        NotificationCenter.default.publisher(for: NSNotification.Name.GCControllerDidStopBeingCurrent )
            .sink(receiveValue: {
                print("Controller stop current",$0)
            })
            .store(in: &cancellable)
    }

    private func onControllerConnected(notification: Notification) {
        setupControllers()
        sendConnectionEvent(true)
    }

    private func setupControllers() {
        var player = 0
        for controller in GCController.controllers() {
            if let gamepad = controller.extendedGamepad {
                setup(extendedGamepad: gamepad, player: player)
                player += 1
            } else if let gamepad = controller.microGamepad {
                setup(microGamepad: gamepad, player: player)
                player += 1
            }
        }
    }

    private func handle(pad: GCControllerDirectionPad, player: Int) {
        if pad.left.isPressed {
            guard lastDPadButton != .left else { return }
            lastDPadButton = .left
            sendGamepad(.init(player: player, button: .left, pressed: true))
        } else if pad.right.isPressed {
            guard lastDPadButton != .right else { return }
            lastDPadButton = .right
            sendGamepad(.init(player: player, button: .right, pressed: true))
        } else if pad.up.isPressed {
            guard lastDPadButton != .up else { return }
            lastDPadButton = .up
            sendGamepad(.init(player: player, button: .up, pressed: true))
        } else if pad.down.isPressed {
            guard lastDPadButton != .down else { return }
            lastDPadButton = .down
            sendGamepad(.init(player: player, button: .down, pressed: true))
        } else if let button = lastDPadButton {
            sendGamepad(.init(player: player, button: button, pressed: false))
            lastDPadButton = nil
        }
    }

    /// Such as a Nimbus
    private func setup(extendedGamepad: GCExtendedGamepad, player: Int) {
        extendedGamepad.controller?.playerIndex = GCControllerPlayerIndex(rawValue: player)!

        extendedGamepad.valueChangedHandler = { gamepad, element in
            switch element {

            case gamepad.buttonMenu:
                self.sendGamepad(.init(player: player, button: .menu, pressed: gamepad.buttonMenu.isPressed))

            case gamepad.dpad:
                self.handle(pad: gamepad.dpad, player: player)

            case gamepad.buttonA:
                self.sendGamepad(.init(player: player, button: .a, pressed: gamepad.buttonA.isPressed))
            case gamepad.buttonB:
                self.sendGamepad(.init(player: player, button: .b, pressed: gamepad.buttonB.isPressed))
            case gamepad.buttonX:
                self.sendGamepad(.init(player: player, button: .x, pressed: gamepad.buttonX.isPressed))
            case gamepad.buttonY:
                self.sendGamepad(.init(player: player, button: .y, pressed: gamepad.buttonY.isPressed))

            case gamepad.leftShoulder:
                self.sendGamepad(.init(player: player, button: .l1, pressed: gamepad.leftShoulder.isPressed))
            case gamepad.rightShoulder:
                self.sendGamepad(.init(player: player, button: .r1, pressed: gamepad.rightShoulder.isPressed))
            case gamepad.leftTrigger:
                self.sendGamepad(.init(player: player, button: .l2, pressed: gamepad.leftTrigger.isPressed))
            case gamepad.rightTrigger:
                self.sendGamepad(.init(player: player, button: .r2, pressed: gamepad.rightTrigger.isPressed))

            default:
                break
            }
        }
    }

    private func setup(microGamepad: GCMicroGamepad, player: Int) {
        microGamepad.reportsAbsoluteDpadValues = true
        microGamepad.allowsRotation = true

        microGamepad.valueChangedHandler = { gamepad, element in
            switch element {

            case gamepad.dpad:
                self.handle(pad: gamepad.dpad, player: player)

            case gamepad.buttonA:
                self.sendGamepad(.init(player: player, button: .a, pressed: gamepad.buttonA.isPressed))
            case gamepad.buttonX:
                self.sendGamepad(.init(player: player, button: .x, pressed: gamepad.buttonX.isPressed))

            default:
                break
            }
        }
    }

}

// MARK: - Keyboard

#if os(macOS)
import Cocoa
#endif

extension InputStore {

    private func addKeyboard() {
        #if os(macOS)
        addMacOSKeyboard()
        #else
        addCommonKeyboard()
        #endif
    }

    private func addCommonKeyboard() {
        NotificationCenter.default.publisher(for: NSNotification.Name.GCKeyboardDidConnect)
            .sink(receiveValue: onKeyboardConnected)
            .store(in: &cancellable)
    }

    private func onKeyboardConnected(notification: Notification) {
        setupKeyboard()
    }

    /// We can't use it in macOS because of error sound on a key press
    private func setupKeyboard() {
        guard let keyboard = GCKeyboard.coalesced?.keyboardInput else { return }

        keyboard.keyChangedHandler = { (keyboard, key, keyCode, pressed) in
//            if let button = self.settingsStore.p1KeyboardMap[keyCode] {
//                self.send(.init(player: 1, button: button, pressed: pressed))
//            } else if let button = self.settingsStore.p2KeyboardMap[keyCode] {
//                self.send(.init(player: 2, button: button, pressed: pressed))
//            }
        }
    }

    #if os(macOS)
    private func addMacOSKeyboard() {
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink(receiveValue: { _ in
                self.isActiveWindow = true
            })
            .store(in: &cancellable)
        NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
            .sink(receiveValue: { _ in
                self.isActiveWindow = false
            })
            .store(in: &cancellable)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyUp) {
            self.keyUp(with: $0)
        }

    }

    private func keyDown(with event: NSEvent) -> NSEvent? {
        if let button = self.p1KeyboardMap[event.keyCode] {
            guard self.sendKeyboard(.init(player: 1, button: button, pressed: true)) else {
                return event
            }
        } else if let button = self.p2KeyboardMap[event.keyCode] {
            guard self.sendKeyboard(.init(player: 2, button: button, pressed: true)) else {
                return event
            }
        }
        return nil
    }

    private func keyUp(with event: NSEvent) -> NSEvent? {
        if let button = self.p1KeyboardMap[event.keyCode] {
            guard self.sendKeyboard(.init(player: 1, button: button, pressed: false)) else {
                return event
            }
        } else if let button = self.p2KeyboardMap[event.keyCode] {
            guard self.sendKeyboard(.init(player: 2, button: button, pressed: false)) else {
                return event
            }
        }
        return nil
    }
    #endif

}

