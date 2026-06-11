import XCTest
@testable import SnapMotion

final class AvatarExpressionMapperTests: XCTestCase {
    func testMapsAndClampsBlendShapeWeights() {
        var recipe = AvatarRecipe.fixture
        recipe = AvatarRecipe(
            schemaVersion: recipe.schemaVersion,
            avatarID: recipe.avatarID,
            displayName: recipe.displayName,
            rig: .init(
                templateID: recipe.rig.templateID,
                morphCalibration: [
                    "blink_L": 2,
                    "blink_R": 0.5,
                    "jaw_open": 3,
                    "smile_L": 1,
                    "smile_R": 1
                ]
            ),
            face: recipe.face,
            skin: recipe.skin,
            eyes: recipe.eyes,
            brows: recipe.brows,
            nose: recipe.nose,
            mouth: recipe.mouth,
            hair: recipe.hair,
            accessories: recipe.accessories,
            materials: recipe.materials
        )

        let frame = FaceTrackingFrame(
            timestamp: 1,
            pose: FacePose(yaw: 12, pitch: -4, roll: 2),
            blendShapes: [
                .eyeBlinkLeft: 0.7,
                .eyeBlinkRight: 0.8,
                .jawOpen: 0.5,
                .mouthSmileLeft: 0.25,
                .mouthSmileRight: 0.75
            ],
            lightEstimate: 500
        )

        let expression = AvatarExpressionMapper().expression(from: frame, recipe: recipe)

        XCTAssertEqual(expression.pose, frame.pose)
        XCTAssertEqual(expression.morphWeights["blink_L"] ?? -1, 1, accuracy: 0.0001)
        XCTAssertEqual(expression.morphWeights["blink_R"] ?? -1, 0.4, accuracy: 0.0001)
        XCTAssertEqual(expression.morphWeights["jaw_open"] ?? -1, 1, accuracy: 0.0001)
        XCTAssertEqual(expression.morphWeights["smile_L"] ?? -1, 0.25, accuracy: 0.0001)
        XCTAssertEqual(expression.morphWeights["smile_R"] ?? -1, 0.75, accuracy: 0.0001)
    }
}
