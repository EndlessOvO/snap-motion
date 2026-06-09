import Foundation
import simd

struct FacePoseEstimator {
    func estimatePose(from transform: simd_float4x4) -> FacePose {
        let yaw = atan2(Double(transform.columns.0.z), Double(transform.columns.0.x))
        let pitch = atan2(-Double(transform.columns.1.z), Double(transform.columns.2.z))
        let roll = atan2(Double(transform.columns.1.x), Double(transform.columns.1.y))

        return FacePose(
            yaw: yaw.radiansToDegrees,
            pitch: pitch.radiansToDegrees,
            roll: roll.radiansToDegrees
        )
    }
}

private extension Double {
    var radiansToDegrees: Double {
        self * 180 / .pi
    }
}
