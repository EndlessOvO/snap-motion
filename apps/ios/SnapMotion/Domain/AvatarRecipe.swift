import Foundation

struct AvatarRecipe: Codable, Equatable, Identifiable {
    let schemaVersion: Int
    let avatarID: String
    let displayName: String?
    let rig: Rig
    let face: Face
    let skin: Skin
    let eyes: Eyes
    let brows: Brows
    let nose: Nose
    let mouth: Mouth
    let hair: Hair
    let accessories: [Accessory]
    let materials: Materials

    var id: String { avatarID }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case avatarID = "avatar_id"
        case displayName = "display_name"
        case rig
        case face
        case skin
        case eyes
        case brows
        case nose
        case mouth
        case hair
        case accessories
        case materials
    }
}

extension AvatarRecipe {
    struct Rig: Codable, Equatable {
        let templateID: String
        let morphCalibration: [String: Double]

        enum CodingKeys: String, CodingKey {
            case templateID = "template_id"
            case morphCalibration = "morph_calibration"
        }
    }

    struct Face: Codable, Equatable {
        let shape: FaceShape
        let roundness: Double
        let jawWidth: Double
        let cheekFullness: Double

        enum CodingKeys: String, CodingKey {
            case shape
            case roundness
            case jawWidth = "jaw_width"
            case cheekFullness = "cheek_fullness"
        }
    }

    struct Skin: Codable, Equatable {
        let toneHex: String
        let warmth: Double
        let roughness: Double

        enum CodingKeys: String, CodingKey {
            case toneHex = "tone_hex"
            case warmth
            case roughness
        }
    }

    struct Eyes: Codable, Equatable {
        let shape: EyeShape
        let colorHex: String
        let size: Double
        let spacing: Double

        enum CodingKeys: String, CodingKey {
            case shape
            case colorHex = "color_hex"
            case size
            case spacing
        }
    }

    struct Brows: Codable, Equatable {
        let shape: BrowShape
        let colorHex: String
        let thickness: Double

        enum CodingKeys: String, CodingKey {
            case shape
            case colorHex = "color_hex"
            case thickness
        }
    }

    struct Nose: Codable, Equatable {
        let style: NoseStyle
        let width: Double
        let length: Double
    }

    struct Mouth: Codable, Equatable {
        let style: MouthStyle
        let width: Double
        let fullness: Double
    }

    struct Hair: Codable, Equatable {
        let style: HairStyle
        let colorHex: String
        let facialHair: FacialHair?

        enum CodingKeys: String, CodingKey {
            case style
            case colorHex = "color_hex"
            case facialHair = "facial_hair"
        }
    }

    struct Accessory: Codable, Equatable, Identifiable {
        let type: AccessoryType
        let style: String
        let colorHex: String?

        var id: String { "\(type.rawValue)-\(style)-\(colorHex ?? "none")" }

        enum CodingKeys: String, CodingKey {
            case type
            case style
            case colorHex = "color_hex"
        }
    }

    struct Materials: Codable, Equatable {
        let skinTextureURL: URL
        let hairTextureURL: URL
        let extraTextureURLs: [URL]

        enum CodingKeys: String, CodingKey {
            case skinTextureURL = "skin_texture_url"
            case hairTextureURL = "hair_texture_url"
            case extraTextureURLs = "extra_texture_urls"
        }
    }
}

enum FaceShape: String, Codable {
    case round
    case oval
    case heart
    case square
    case long
}

enum EyeShape: String, Codable {
    case almond
    case round
    case monolid
    case hooded
    case upturned
    case downturned
}

enum BrowShape: String, Codable {
    case softArch = "soft_arch"
    case straight
    case rounded
    case angled
}

enum NoseStyle: String, Codable {
    case button
    case straight
    case soft
    case defined
}

enum MouthStyle: String, Codable {
    case softSmile = "soft_smile"
    case small
    case wide
    case full
}

enum HairStyle: String, Codable {
    case short
    case bob
    case long
    case curly
    case wavy
    case buzz
    case bald
    case ponytail
}

enum FacialHair: String, Codable {
    case none
    case stubble
    case mustache
    case beard
}

enum AccessoryType: String, Codable {
    case glasses
    case earrings
    case hat
}

extension AvatarRecipe {
    static let fixture = AvatarRecipe(
        schemaVersion: 1,
        avatarID: "avatar_fixture",
        displayName: "Snap Friend",
        rig: Rig(
            templateID: "cute_avatar_v1",
            morphCalibration: [
                "blink_L": 1.0,
                "blink_R": 1.0,
                "jaw_open": 1.0,
                "smile_L": 1.0,
                "smile_R": 1.0
            ]
        ),
        face: Face(shape: .round, roundness: 0.72, jawWidth: 0.42, cheekFullness: 0.78),
        skin: Skin(toneHex: "#E9B98F", warmth: 0.62, roughness: 0.36),
        eyes: Eyes(shape: .almond, colorHex: "#4A2C1A", size: 0.64, spacing: 0.52),
        brows: Brows(shape: .softArch, colorHex: "#2B1B12", thickness: 0.58),
        nose: Nose(style: .soft, width: 0.46, length: 0.5),
        mouth: Mouth(style: .softSmile, width: 0.55, fullness: 0.48),
        hair: Hair(style: .wavy, colorHex: "#24170F", facialHair: .none),
        accessories: [],
        materials: Materials(
            skinTextureURL: URL(string: "https://assets.snap-motion.local/skin-fixture.png")!,
            hairTextureURL: URL(string: "https://assets.snap-motion.local/hair-fixture.png")!,
            extraTextureURLs: []
        )
    )
}
