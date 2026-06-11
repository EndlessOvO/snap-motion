import Foundation
import UIKit

struct DeviceInfoProvider {
    func makeDevice() -> CaptureManifest.Device {
        CaptureManifest.Device(
            model: UIDevice.current.model,
            osVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            appVersion: appVersion
        )
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let shortVersion = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String

        switch (shortVersion, build) {
        case let (.some(shortVersion), .some(build)):
            return "\(shortVersion) (\(build))"
        case let (.some(shortVersion), .none):
            return shortVersion
        default:
            return "1.0.0"
        }
    }
}
