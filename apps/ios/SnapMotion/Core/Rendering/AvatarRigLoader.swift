import SceneKit

struct AvatarRigLoader {
    func shouldUseProceduralModel(for templateID: String) -> Bool {
        switch templateID {
        case "cute_avatar_v1", "procedural_cute_avatar_v1":
            return true
        default:
            return false
        }
    }

    func loadTemplate(named templateID: String) throws -> SCNScene {
        let sceneName = sceneName(for: templateID)
        guard let scene = SCNScene(named: sceneName) else {
            throw AvatarRigLoaderError.missingTemplate(sceneName)
        }

        return scene
    }

    private func sceneName(for templateID: String) -> String {
        switch templateID {
        case "asset_cute_avatar_v1":
            return "AvatarAssets.scnassets/CuteAvatarTemplate.scn"
        default:
            return "AvatarAssets.scnassets/\(templateID).scn"
        }
    }
}

enum AvatarRigLoaderError: Error, LocalizedError {
    case missingTemplate(String)

    var errorDescription: String? {
        switch self {
        case .missingTemplate(let name):
            return "Missing avatar template: \(name)"
        }
    }
}
