import XCTest

final class SnapMotionUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCameraPermissionDeniedState() {
        let app = launch(scenario: "camera_denied")
        confirmAgeIfNeeded(app)

        XCTAssertTrue(app.staticTexts["Camera access is disabled."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Retry Capture"].exists)
    }

    func testUnsupportedFaceTrackingState() {
        let app = launch(scenario: "unsupported_face_tracking")
        confirmAgeIfNeeded(app)

        XCTAssertTrue(app.staticTexts["TrueDepth face tracking is not available on this device."].waitForExistence(timeout: 3))
    }

    func testAvatarPreviewLoadsFixture() {
        let app = launch(scenario: "preview_fixture")

        XCTAssertTrue(app.navigationBars["Avatar Preview"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.segmentedControls["Preview Mode"].exists)
        XCTAssertTrue(app.staticTexts["Blink"].exists)
        XCTAssertTrue(app.staticTexts["Mouth"].exists)
        XCTAssertTrue(app.staticTexts["Smile"].exists)
    }

    func testGenerationFailureState() {
        let app = launch(scenario: "generation_failure")
        confirmAgeIfNeeded(app)

        XCTAssertTrue(app.staticTexts["Generation failed"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["UI test generation failure."].exists)
        XCTAssertTrue(app.buttons["Preview Fixture"].exists)
    }

    func testAgeGateRequiresConfirmation() {
        let app = launch(scenario: "camera_denied", resetAgeGate: true)

        XCTAssertTrue(app.staticTexts["Age Confirmation"].waitForExistence(timeout: 3))
        app.buttons["I am 13 or older"].tap()
        XCTAssertTrue(app.staticTexts["Camera access is disabled."].waitForExistence(timeout: 3))
    }

    private func launch(scenario: String, resetAgeGate: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SNAP_MOTION_UI_TEST_SCENARIO"] = scenario
        if resetAgeGate {
            app.launchEnvironment["SNAP_MOTION_RESET_AGE_GATE"] = "1"
        }
        app.launch()
        return app
    }

    private func confirmAgeIfNeeded(_ app: XCUIApplication) {
        if app.staticTexts["Age Confirmation"].waitForExistence(timeout: 1) {
            app.buttons["I am 13 or older"].tap()
        }
    }
}
