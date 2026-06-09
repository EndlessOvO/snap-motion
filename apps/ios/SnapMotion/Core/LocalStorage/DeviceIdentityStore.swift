import Foundation

struct DeviceIdentityStore {
    private let key = "snap_motion_anonymous_device_id"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func deviceID() -> String {
        if let existing = defaults.string(forKey: key) {
            return existing
        }

        let newID = UUID().uuidString
        defaults.set(newID, forKey: key)
        return newID
    }
}
