import AVFoundation
import XCTest
@testable import SnapMotion

@MainActor
final class FaceEnrollmentViewModelTests: XCTestCase {
    func testBlinkCompletesFromLowExpressionPeak() async {
        let viewModel = await makeRunningViewModelAtBlink()

        viewModel.ingest(
            frame: frame(for: .blink, blendShapes: [.eyeBlinkLeft: 0.17]),
            sharpness: 0.2,
            imageURL: imageURL("blink-low-peak")
        )

        XCTAssertTrue(viewModel.completedSlots.contains(.blink))
        XCTAssertEqual(viewModel.currentSlot, .mouthOpen)
    }

    func testBlinkFallsBackAfterStableFaceWindow() async {
        let viewModel = await makeRunningViewModelAtBlink()

        for index in 0..<23 {
            viewModel.ingest(
                frame: frame(for: .blink),
                sharpness: 0.45,
                imageURL: imageURL("blink-stable-\(index)")
            )
        }

        XCTAssertFalse(viewModel.completedSlots.contains(.blink))

        viewModel.ingest(
            frame: frame(for: .blink),
            sharpness: 0.45,
            imageURL: imageURL("blink-stable-final")
        )

        XCTAssertTrue(viewModel.completedSlots.contains(.blink))
        XCTAssertEqual(viewModel.currentSlot, .mouthOpen)
    }

    func testMouthCompletesFromLowExpressionPeak() async {
        let viewModel = await makeRunningViewModelAtMouth()

        viewModel.ingest(
            frame: frame(for: .mouthOpen, blendShapes: [.jawOpen: 0.19]),
            sharpness: 0.2,
            imageURL: imageURL("mouth-low-peak")
        )

        XCTAssertTrue(viewModel.completedSlots.contains(.mouthOpen))
        XCTAssertEqual(viewModel.currentSlot, .smile)
    }

    func testMouthFallsBackAfterStableFaceWindow() async {
        let viewModel = await makeRunningViewModelAtMouth()

        for index in 0..<29 {
            viewModel.ingest(
                frame: frame(for: .mouthOpen),
                sharpness: 0.45,
                imageURL: imageURL("mouth-stable-\(index)")
            )
        }

        XCTAssertFalse(viewModel.completedSlots.contains(.mouthOpen))

        viewModel.ingest(
            frame: frame(for: .mouthOpen),
            sharpness: 0.45,
            imageURL: imageURL("mouth-stable-final")
        )

        XCTAssertTrue(viewModel.completedSlots.contains(.mouthOpen))
        XCTAssertEqual(viewModel.currentSlot, .smile)
    }

    private func makeRunningViewModelAtBlink() async -> FaceEnrollmentViewModel {
        await makeRunningViewModel(until: .blink)
    }

    private func makeRunningViewModelAtMouth() async -> FaceEnrollmentViewModel {
        await makeRunningViewModel(until: .mouthOpen)
    }

    private func makeRunningViewModel(until targetSlot: CaptureSlot) async -> FaceEnrollmentViewModel {
        let viewModel = FaceEnrollmentViewModel(
            permissionService: .fixed(status: .authorized),
            forceFaceTrackingSupport: true
        )
        _ = await viewModel.prepareCapture(isFaceTrackingSupported: true)

        while viewModel.currentSlot != targetSlot {
            let slot = viewModel.currentSlot
            let blendShapes: [FaceBlendShape: Double]
            switch slot {
            case .blink:
                blendShapes = [.eyeBlinkLeft: 0.17]
            case .mouthOpen:
                blendShapes = [.jawOpen: 0.19]
            case .smile:
                blendShapes = [.mouthSmileLeft: 0.23, .mouthSmileRight: 0.23]
            case .neutralFront, .turnLeft, .turnRight, .lookUp, .lookDown:
                blendShapes = [:]
            }
            viewModel.ingest(
                frame: frame(for: slot, blendShapes: blendShapes),
                sharpness: 1,
                imageURL: imageURL(slot.rawValue)
            )
        }

        return viewModel
    }

    private func frame(
        for slot: CaptureSlot,
        blendShapes: [FaceBlendShape: Double] = [:]
    ) -> FaceTrackingFrame {
        FaceTrackingFrame(
            timestamp: 1,
            pose: pose(for: slot),
            blendShapes: blendShapes,
            lightEstimate: 500
        )
    }

    private func pose(for slot: CaptureSlot) -> FacePose {
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

    private func imageURL(_ name: String) -> URL {
        URL(fileURLWithPath: "/tmp/\(name).jpg")
    }
}
