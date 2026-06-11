import SceneKit
import XCTest
@testable import SnapMotion

final class AvatarProceduralRigFactoryTests: XCTestCase {
    func testBuildsProceduralMeshWithAllExpressionTargets() {
        let scene = AvatarProceduralRigFactory().makeScene(recipe: .fixture)

        let skin = scene.rootNode.childNode(withName: "skin", recursively: true)
        XCTAssertNotNil(skin)
        XCTAssertGreaterThan(skin?.geometry?.sources(for: .vertex).first?.vectorCount ?? 0, 400)

        let expectedTargets: Set<String> = [
            "blink_L",
            "blink_R",
            "jaw_open",
            "smile_L",
            "smile_R",
            "brow_up_L",
            "brow_up_R",
            "mouth_funnel",
            "mouth_pucker",
            "cheek_squint_L",
            "cheek_squint_R"
        ]

        XCTAssertTrue(collectMorphTargetNames(in: scene.rootNode).isSuperset(of: expectedTargets))
    }

    func testRecipeParametersChangeGeneratedModelProportions() {
        let compactRecipe = AvatarRecipe.fixture
        let expressiveRecipe = recipe(
            face: .init(shape: .long, roundness: 0.18, jawWidth: 0.86, cheekFullness: 0.22),
            eyes: .init(shape: .round, colorHex: "#336688", size: 1, spacing: 1),
            brows: .init(shape: .angled, colorHex: "#101010", thickness: 0.95),
            nose: .init(style: .defined, width: 0.92, length: 0.9),
            mouth: .init(style: .wide, width: 1, fullness: 0.84),
            hair: .init(style: .long, colorHex: "#111111", facialHair: .beard),
            accessories: [
                .init(type: .glasses, style: "round", colorHex: "#222222"),
                .init(type: .hat, style: "cap", colorHex: "#445577")
            ]
        )

        let compactScene = AvatarProceduralRigFactory().makeScene(recipe: compactRecipe)
        let expressiveScene = AvatarProceduralRigFactory().makeScene(recipe: expressiveRecipe)

        XCTAssertLessThan(
            abs(compactScene.rootNode.childNode(withName: "leftEye", recursively: true)?.position.x ?? 0),
            abs(expressiveScene.rootNode.childNode(withName: "leftEye", recursively: true)?.position.x ?? 0)
        )
        XCTAssertLessThan(
            abs(compactScene.rootNode.childNode(withName: "rightEye", recursively: true)?.position.x ?? 0),
            abs(expressiveScene.rootNode.childNode(withName: "rightEye", recursively: true)?.position.x ?? 0)
        )
        XCTAssertNotNil(expressiveScene.rootNode.childNode(withName: "facialHair", recursively: true))
        XCTAssertNotNil(expressiveScene.rootNode.childNode(withName: "hat", recursively: true))
    }

    private func recipe(
        face: AvatarRecipe.Face,
        eyes: AvatarRecipe.Eyes,
        brows: AvatarRecipe.Brows,
        nose: AvatarRecipe.Nose,
        mouth: AvatarRecipe.Mouth,
        hair: AvatarRecipe.Hair,
        accessories: [AvatarRecipe.Accessory]
    ) -> AvatarRecipe {
        AvatarRecipe(
            schemaVersion: AvatarRecipe.fixture.schemaVersion,
            avatarID: "avatar_procedural_test",
            displayName: AvatarRecipe.fixture.displayName,
            rig: AvatarRecipe.fixture.rig,
            face: face,
            skin: AvatarRecipe.fixture.skin,
            eyes: eyes,
            brows: brows,
            nose: nose,
            mouth: mouth,
            hair: hair,
            accessories: accessories,
            materials: AvatarRecipe.fixture.materials
        )
    }

    private func collectMorphTargetNames(in node: SCNNode) -> Set<String> {
        var names = Set<String>()

        if let morpher = node.morpher {
            names.formUnion(morpher.targets.compactMap(\.name))
        }

        for child in node.childNodes {
            names.formUnion(collectMorphTargetNames(in: child))
        }

        return names
    }
}
