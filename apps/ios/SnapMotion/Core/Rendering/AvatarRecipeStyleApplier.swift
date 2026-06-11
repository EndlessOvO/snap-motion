import Foundation
import SceneKit
import UIKit

struct AvatarRecipeStyleApplier {
    func apply(recipe: AvatarRecipe, cachedTextureURLs: [URL: URL] = [:], to scene: SCNScene) {
        applyColor(recipe.skin.toneHex, toNodesNamed: ["skin", "nose"], in: scene)
        applyColor(recipe.hair.colorHex, toNodesNamed: ["hair"], in: scene)
        applyColor(recipe.eyes.colorHex, toNodesNamed: ["leftEye", "rightEye"], in: scene)
        applyColor(recipe.brows.colorHex, toNodesNamed: ["leftBrow", "rightBrow"], in: scene)
        applyTexture(cachedTextureURLs[recipe.materials.skinTextureURL], toNodesNamed: ["skin"], in: scene)
        applyTexture(cachedTextureURLs[recipe.materials.hairTextureURL], toNodesNamed: ["hair"], in: scene)

        for accessory in recipe.accessories {
            if let colorHex = accessory.colorHex {
                applyColor(colorHex, toNodesNamed: [accessory.type.rawValue], in: scene)
            }
        }
    }

    private func applyColor(_ hexString: String, toNodesNamed names: Set<String>, in scene: SCNScene) {
        guard let color = UIColor(hexString: hexString) else {
            return
        }

        scene.rootNode.enumerateChildNodes { node, _ in
            guard let name = node.name, names.contains(name) else {
                return
            }

            node.geometry?.materials.forEach { material in
                material.diffuse.contents = color
            }
        }
    }

    private func applyTexture(_ textureURL: URL?, toNodesNamed names: Set<String>, in scene: SCNScene) {
        guard let textureURL else {
            return
        }

        scene.rootNode.enumerateChildNodes { node, _ in
            guard let name = node.name, names.contains(name) else {
                return
            }

            node.geometry?.materials.forEach { material in
                material.diffuse.contents = textureURL
            }
        }
    }
}
