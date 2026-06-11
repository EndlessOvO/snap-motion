import Foundation
import XCTest
@testable import SnapMotion

final class LocalAvatarRecipeFactoryTests: XCTestCase {
    func testMakesStableProceduralRecipeFromManifest() throws {
        let manifest = CaptureManifest.localFactoryFixture
        let factory = LocalAvatarRecipeFactory()

        let first = factory.makeRecipe(from: manifest, deviceID: "device-local")
        let second = factory.makeRecipe(from: manifest, deviceID: "device-local")

        XCTAssertEqual(first, second)
        XCTAssertTrue(first.avatarID.hasPrefix("avatar_local_"))
        XCTAssertEqual(first.rig.templateID, "procedural_cute_avatar_v1")
        XCTAssertGreaterThan(first.rig.morphCalibration["jaw_open"] ?? 0, 0)

        let encoded = try JSONEncoder().encode(first)
        let decoded = try JSONDecoder().decode(AvatarRecipe.self, from: encoded)
        XCTAssertEqual(decoded, first)
    }
}

private extension CaptureManifest {
    static let localFactoryFixture = CaptureManifest(
        schemaVersion: 1,
        createdAt: Date(timeIntervalSince1970: 100),
        device: .init(model: "iPhone", osVersion: "26.4.1", appVersion: "1.0.0"),
        captureSlots: CaptureSlot.allCases.map { slot in
            CapturedFrame(
                slot: slot,
                localURL: URL(fileURLWithPath: "/tmp/\(slot.rawValue).jpg"),
                quality: FaceQualityScore(
                    lighting: 0.8,
                    sharpness: 0.85,
                    poseMatch: 0.9,
                    expressionMatch: expressionMatch(for: slot)
                ),
                pose: pose(for: slot),
                capturedAt: Date(timeIntervalSince1970: 100)
            )
        }
    )

    static func expressionMatch(for slot: CaptureSlot) -> Double {
        switch slot {
        case .blink:
            return 0.4
        case .mouthOpen:
            return 0.5
        case .smile:
            return 0.6
        case .neutralFront, .turnLeft, .turnRight, .lookUp, .lookDown:
            return 1
        }
    }

    static func pose(for slot: CaptureSlot) -> FacePose {
        switch slot {
        case .turnLeft:
            return FacePose(yaw: -24, pitch: 0, roll: 0)
        case .turnRight:
            return FacePose(yaw: 24, pitch: 0, roll: 0)
        case .lookUp:
            return FacePose(yaw: 0, pitch: 14, roll: 0)
        case .lookDown:
            return FacePose(yaw: 0, pitch: -14, roll: 0)
        case .neutralFront, .blink, .mouthOpen, .smile:
            return .neutral
        }
    }
}
