import Foundation
import simd

struct FaceTrackingFrame: Equatable {
    let timestamp: TimeInterval
    let pose: FacePose
    let blendShapes: [FaceBlendShape: Double]
    let lightEstimate: Double?

    func blendShape(_ shape: FaceBlendShape) -> Double {
        blendShapes[shape] ?? 0
    }
}

struct FacePose: Codable, Equatable {
    let yaw: Double
    let pitch: Double
    let roll: Double

    static let neutral = FacePose(yaw: 0, pitch: 0, roll: 0)
}

struct FaceQualityScore: Codable, Equatable, Comparable {
    let lighting: Double
    let sharpness: Double
    let poseMatch: Double
    let expressionMatch: Double

    var total: Double {
        (lighting * 0.25) + (sharpness * 0.3) + (poseMatch * 0.3) + (expressionMatch * 0.15)
    }

    static func < (lhs: FaceQualityScore, rhs: FaceQualityScore) -> Bool {
        lhs.total < rhs.total
    }
}
