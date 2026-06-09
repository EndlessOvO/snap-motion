import Foundation

struct CaptureManifest: Codable, Equatable {
    let schemaVersion: Int
    let createdAt: Date
    let device: Device
    let captureSlots: [CapturedFrame]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case createdAt = "created_at"
        case device
        case captureSlots = "capture_slots"
    }
}

extension CaptureManifest {
    struct Device: Codable, Equatable {
        let model: String
        let osVersion: String
        let appVersion: String

        enum CodingKeys: String, CodingKey {
            case model
            case osVersion = "os_version"
            case appVersion = "app_version"
        }
    }

    struct CapturedFrame: Codable, Equatable, Identifiable {
        let slot: CaptureSlot
        let localURL: URL
        let quality: FaceQualityScore
        let pose: FacePose
        let capturedAt: Date

        var id: CaptureSlot { slot }

        enum CodingKeys: String, CodingKey {
            case slot
            case localURL = "local_url"
            case quality
            case pose
            case capturedAt = "captured_at"
        }
    }
}

enum CaptureSlot: String, Codable, CaseIterable {
    case neutralFront
    case turnLeft
    case turnRight
    case lookUp
    case lookDown
    case blink
    case mouthOpen
    case smile

    var prompt: String {
        switch self {
        case .neutralFront:
            return "Look straight ahead"
        case .turnLeft:
            return "Turn left"
        case .turnRight:
            return "Turn right"
        case .lookUp:
            return "Look up"
        case .lookDown:
            return "Look down"
        case .blink:
            return "Blink"
        case .mouthOpen:
            return "Open your mouth"
        case .smile:
            return "Smile"
        }
    }
}
