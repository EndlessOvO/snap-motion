import AVFoundation
import Foundation

struct UITestLaunchConfiguration {
    let scenario: Scenario

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        scenario = Scenario(rawValue: environment["SNAP_MOTION_UI_TEST_SCENARIO"] ?? "") ?? .normal
        if environment["SNAP_MOTION_RESET_AGE_GATE"] == "1" {
            UserDefaults.standard.removeObject(forKey: "snap_motion_age_confirmed")
        }
    }

    enum Scenario: String {
        case normal
        case cameraDenied = "camera_denied"
        case unsupportedFaceTracking = "unsupported_face_tracking"
        case previewFixture = "preview_fixture"
        case generationFailure = "generation_failure"
    }

    var isUITesting: Bool {
        scenario != .normal
    }
}
