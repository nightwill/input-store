import SwiftUI

struct InputStoreKey: EnvironmentKey {

    public static let defaultValue: InputStore = .init()

}

extension EnvironmentValues {

    var inputStore: InputStore {
        get { self[InputStoreKey.self] }
        set { self[InputStoreKey.self] = newValue }
    }

}
