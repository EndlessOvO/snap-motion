import Foundation

struct AvatarExpressionMapper {
    private let rigMapping: [FaceBlendShape: String] = [
        .eyeBlinkLeft: "blink_L",
        .eyeBlinkRight: "blink_R",
        .jawOpen: "jaw_open",
        .mouthSmileLeft: "smile_L",
        .mouthSmileRight: "smile_R",
        .browInnerUp: "brow_up_L",
        .browOuterUpLeft: "brow_up_L",
        .browOuterUpRight: "brow_up_R",
        .mouthFunnel: "mouth_funnel",
        .mouthPucker: "mouth_pucker",
        .cheekSquintLeft: "cheek_squint_L",
        .cheekSquintRight: "cheek_squint_R"
    ]

    func expression(from frame: FaceTrackingFrame, recipe: AvatarRecipe) -> AvatarExpressionFrame {
        var weights: [String: Double] = [:]

        for (shape, rigName) in rigMapping {
            let calibration = recipe.rig.morphCalibration[rigName] ?? 1
            let value = (frame.blendShape(shape) * calibration).clamped(to: 0...1)
            weights[rigName] = max(weights[rigName] ?? 0, value)
        }

        return AvatarExpressionFrame(morphWeights: weights, pose: frame.pose)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
