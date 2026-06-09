import Foundation
import SwiftUI

@MainActor
final class FaceEnrollmentViewModel: ObservableObject {
    @Published private(set) var currentSlot: CaptureSlot = .neutralFront
    @Published private(set) var completedSlots: Set<CaptureSlot> = []
    @Published private(set) var qualityMessage: String = "Center your face in the oval."
    @Published private(set) var canContinue: Bool = false
    @Published private(set) var selectedFrames: [CaptureSlot: CaptureManifest.CapturedFrame] = [:]

    private let evaluator = FaceQualityEvaluator()
    private let selector = CaptureFrameSelector()

    var progress: Double {
        Double(completedSlots.count) / Double(CaptureSlot.allCases.count)
    }

    var prompt: String {
        currentSlot.prompt
    }

    func ingest(frame: FaceTrackingFrame, sharpness: Double, imageURL: URL) {
        let quality = evaluator.score(frame: frame, targetSlot: currentSlot, sharpness: sharpness)
        qualityMessage = message(for: quality)

        guard quality.total >= 0.72 else {
            return
        }

        let candidate = CaptureManifest.CapturedFrame(
            slot: currentSlot,
            localURL: imageURL,
            quality: quality,
            pose: frame.pose,
            capturedAt: Date()
        )

        selectedFrames = selector.bestFrames(from: Array(selectedFrames.values) + [candidate])
        completedSlots.insert(currentSlot)
        canContinue = selector.isComplete(selectedFrames)
        advanceSlot()
    }

    func makeManifest(device: CaptureManifest.Device) -> CaptureManifest {
        CaptureManifest(
            schemaVersion: 1,
            createdAt: Date(),
            device: device,
            captureSlots: CaptureSlot.allCases.compactMap { selectedFrames[$0] }
        )
    }

    private func advanceSlot() {
        guard let next = CaptureSlot.allCases.first(where: { !completedSlots.contains($0) }) else {
            return
        }

        currentSlot = next
    }

    private func message(for quality: FaceQualityScore) -> String {
        if quality.lighting < 0.5 {
            return "Move to softer, brighter light."
        }
        if quality.sharpness < 0.5 {
            return "Hold still for a clearer frame."
        }
        if quality.poseMatch < 0.5 {
            return currentSlot.prompt
        }
        return "Great, hold that."
    }
}
