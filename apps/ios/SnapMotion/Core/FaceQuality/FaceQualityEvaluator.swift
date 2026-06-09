import Foundation

struct FaceQualityEvaluator {
    private let lightingEvaluator = LightingEvaluator()

    func score(frame: FaceTrackingFrame, targetSlot: CaptureSlot, sharpness: Double) -> FaceQualityScore {
        FaceQualityScore(
            lighting: lightingEvaluator.score(ambientIntensity: frame.lightEstimate),
            sharpness: sharpness.clamped(to: 0...1),
            poseMatch: poseScore(frame.pose, for: targetSlot),
            expressionMatch: expressionScore(frame, for: targetSlot)
        )
    }

    private func poseScore(_ pose: FacePose, for slot: CaptureSlot) -> Double {
        switch slot {
        case .neutralFront, .blink, .mouthOpen, .smile:
            return normalizedDistance(abs(pose.yaw), target: 0, tolerance: 12)
        case .turnLeft:
            return normalizedDistance(pose.yaw, target: -24, tolerance: 18)
        case .turnRight:
            return normalizedDistance(pose.yaw, target: 24, tolerance: 18)
        case .lookUp:
            return normalizedDistance(pose.pitch, target: 14, tolerance: 14)
        case .lookDown:
            return normalizedDistance(pose.pitch, target: -14, tolerance: 14)
        }
    }

    private func expressionScore(_ frame: FaceTrackingFrame, for slot: CaptureSlot) -> Double {
        switch slot {
        case .blink:
            return max(frame.blendShape(.eyeBlinkLeft), frame.blendShape(.eyeBlinkRight))
        case .mouthOpen:
            return frame.blendShape(.jawOpen)
        case .smile:
            return (frame.blendShape(.mouthSmileLeft) + frame.blendShape(.mouthSmileRight)) / 2
        case .neutralFront, .turnLeft, .turnRight, .lookUp, .lookDown:
            return 1
        }
    }

    private func normalizedDistance(_ value: Double, target: Double, tolerance: Double) -> Double {
        max(0, 1 - (abs(value - target) / tolerance))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
