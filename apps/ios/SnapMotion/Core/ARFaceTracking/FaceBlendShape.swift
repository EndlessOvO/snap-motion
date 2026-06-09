import ARKit

enum FaceBlendShape: String, CaseIterable, Codable, Hashable {
    case eyeBlinkLeft
    case eyeBlinkRight
    case jawOpen
    case mouthSmileLeft
    case mouthSmileRight
    case browInnerUp
    case browOuterUpLeft
    case browOuterUpRight
    case mouthFunnel
    case mouthPucker
    case cheekSquintLeft
    case cheekSquintRight

    var arkitLocation: ARFaceAnchor.BlendShapeLocation {
        switch self {
        case .eyeBlinkLeft:
            return .eyeBlinkLeft
        case .eyeBlinkRight:
            return .eyeBlinkRight
        case .jawOpen:
            return .jawOpen
        case .mouthSmileLeft:
            return .mouthSmileLeft
        case .mouthSmileRight:
            return .mouthSmileRight
        case .browInnerUp:
            return .browInnerUp
        case .browOuterUpLeft:
            return .browOuterUpLeft
        case .browOuterUpRight:
            return .browOuterUpRight
        case .mouthFunnel:
            return .mouthFunnel
        case .mouthPucker:
            return .mouthPucker
        case .cheekSquintLeft:
            return .cheekSquintLeft
        case .cheekSquintRight:
            return .cheekSquintRight
        }
    }
}
