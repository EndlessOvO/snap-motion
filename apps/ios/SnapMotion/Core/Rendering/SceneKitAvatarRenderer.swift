import SceneKit
import SwiftUI

@MainActor
final class SceneKitAvatarRenderer: ObservableObject, AvatarRenderer {
    @Published private(set) var scene: SCNScene?
    @Published private(set) var loadNotice: String?

    private let rigLoader = AvatarRigLoader()
    private let assetCache = AvatarAssetCache()
    private var morphersByTargetName: [String: SCNMorpher] = [:]

    func load(recipe: AvatarRecipe) async throws {
        let scene: SCNScene
        let cachedTextureURLs = await assetCache.prefetch(recipe: recipe)

        if rigLoader.shouldUseProceduralModel(for: recipe.rig.templateID) {
            scene = AvatarProceduralRigFactory().makeScene(recipe: recipe)
            loadNotice = nil
        } else {
            do {
                scene = try rigLoader.loadTemplate(named: recipe.rig.templateID)
                AvatarRecipeGeometryApplier().apply(recipe: recipe, to: scene)
                loadNotice = nil
            } catch {
                scene = AvatarProceduralRigFactory().makeScene(recipe: recipe)
                loadNotice = "\(error.localizedDescription) Showing the built-in procedural model."
            }
        }

        AvatarRecipeStyleApplier().apply(recipe: recipe, cachedTextureURLs: cachedTextureURLs, to: scene)
        self.scene = scene
        self.morphersByTargetName = collectMorphers(in: scene.rootNode)
    }

    func apply(expression: AvatarExpressionFrame) {
        for (targetName, weight) in expression.morphWeights {
            guard let morpher = morphersByTargetName[targetName],
                  let targetIndex = morpher.targets.firstIndex(where: { $0.name == targetName })
            else {
                continue
            }

            morpher.setWeight(CGFloat(weight), forTargetAt: targetIndex)
        }

        scene?.rootNode.eulerAngles.y = Float(expression.pose.yaw * .pi / 180)
        scene?.rootNode.eulerAngles.x = Float(expression.pose.pitch * .pi / 180)
    }

    private func collectMorphers(in node: SCNNode) -> [String: SCNMorpher] {
        var morphers: [String: SCNMorpher] = [:]

        if let morpher = node.morpher {
            for target in morpher.targets {
                guard let name = target.name else {
                    continue
                }
                morphers[name] = morpher
            }
        }

        for child in node.childNodes {
            morphers.merge(collectMorphers(in: child)) { current, _ in current }
        }

        return morphers
    }
}

struct AvatarSceneView: UIViewRepresentable {
    let scene: SCNScene?

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        view.scene = scene
    }
}
