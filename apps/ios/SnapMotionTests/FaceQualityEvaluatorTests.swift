import XCTest
@testable import SnapMotion

final class FaceQualityEvaluatorTests: XCTestCase {
    func testScoresGoodNeutralFrameHighly() {
        let frame = FaceTrackingFrame(
            timestamp: 1,
            pose: .neutral,
            blendShapes: [:],
            lightEstimate: 500
        )

        let score = FaceQualityEvaluator().score(frame: frame, targetSlot: .neutralFront, sharpness: 1)

        XCTAssertEqual(score.lighting, 1, accuracy: 0.0001)
        XCTAssertEqual(score.sharpness, 1, accuracy: 0.0001)
        XCTAssertEqual(score.poseMatch, 1, accuracy: 0.0001)
        XCTAssertEqual(score.expressionMatch, 1, accuracy: 0.0001)
        XCTAssertEqual(score.total, 1, accuracy: 0.0001)
    }

    func testScoresTargetExpression() {
        let frame = FaceTrackingFrame(
            timestamp: 1,
            pose: .neutral,
            blendShapes: [.jawOpen: 0.8],
            lightEstimate: 500
        )

        let score = FaceQualityEvaluator().score(frame: frame, targetSlot: .mouthOpen, sharpness: 1)

        XCTAssertEqual(score.expressionMatch, 0.8, accuracy: 0.0001)
        XCTAssertGreaterThan(score.total, 0.9)
    }

    func testScoresBlinkFromEitherEye() {
        let frame = FaceTrackingFrame(
            timestamp: 1,
            pose: .neutral,
            blendShapes: [.eyeBlinkLeft: 0.48, .eyeBlinkRight: 0.12],
            lightEstimate: 500
        )

        let score = FaceQualityEvaluator().score(frame: frame, targetSlot: .blink, sharpness: 0.7)

        XCTAssertEqual(score.expressionMatch, 0.48, accuracy: 0.0001)
        XCTAssertGreaterThan(score.total, 0.64)
    }

    func testRejectsWrongTurnDirection() {
        let frame = FaceTrackingFrame(
            timestamp: 1,
            pose: FacePose(yaw: 24, pitch: 0, roll: 0),
            blendShapes: [:],
            lightEstimate: 500
        )

        let score = FaceQualityEvaluator().score(frame: frame, targetSlot: .turnLeft, sharpness: 1)

        XCTAssertEqual(score.poseMatch, 0, accuracy: 0.0001)
        XCTAssertLessThan(score.total, 0.8)
    }
}
