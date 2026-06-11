import Foundation
import XCTest
@testable import SnapMotion

final class CaptureFrameSelectorTests: XCTestCase {
    func testBestFramesKeepsHighestQualityPerSlot() {
        let lower = frame(slot: .neutralFront, totalQuality: 0.4)
        let higher = frame(slot: .neutralFront, totalQuality: 0.9)
        let smile = frame(slot: .smile, totalQuality: 0.75)

        let selected = CaptureFrameSelector().bestFrames(from: [lower, smile, higher])

        XCTAssertEqual(selected[.neutralFront], higher)
        XCTAssertEqual(selected[.smile], smile)
        XCTAssertEqual(selected.count, 2)
    }

    func testIsCompleteRequiresEverySlot() {
        let selector = CaptureFrameSelector()
        let incomplete: [CaptureSlot: CaptureManifest.CapturedFrame] = [
            .neutralFront: frame(slot: .neutralFront, totalQuality: 1)
        ]
        let complete = Dictionary(
            uniqueKeysWithValues: CaptureSlot.allCases.map { slot in
                (slot, frame(slot: slot, totalQuality: 1))
            }
        )

        XCTAssertFalse(selector.isComplete(incomplete))
        XCTAssertTrue(selector.isComplete(complete))
    }

    private func frame(slot: CaptureSlot, totalQuality: Double) -> CaptureManifest.CapturedFrame {
        CaptureManifest.CapturedFrame(
            slot: slot,
            localURL: URL(fileURLWithPath: "/tmp/\(slot.rawValue).jpg"),
            quality: FaceQualityScore(
                lighting: totalQuality,
                sharpness: totalQuality,
                poseMatch: totalQuality,
                expressionMatch: totalQuality
            ),
            pose: .neutral,
            capturedAt: Date(timeIntervalSince1970: totalQuality)
        )
    }
}
