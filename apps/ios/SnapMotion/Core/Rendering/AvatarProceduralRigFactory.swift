import SceneKit
import UIKit

struct AvatarProceduralRigFactory {
    func makeScene(recipe: AvatarRecipe) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let root = SCNNode()
        root.name = "avatarRoot"
        scene.rootNode.addChildNode(root)

        root.addChildNode(face(recipe: recipe))
        root.addChildNode(hair(recipe: recipe))
        root.addChildNode(eye(name: "leftEye", side: .left, recipe: recipe))
        root.addChildNode(eye(name: "rightEye", side: .right, recipe: recipe))
        root.addChildNode(brow(name: "leftBrow", side: .left, recipe: recipe))
        root.addChildNode(brow(name: "rightBrow", side: .right, recipe: recipe))
        root.addChildNode(cheek(name: "leftCheek", side: .left, recipe: recipe))
        root.addChildNode(cheek(name: "rightCheek", side: .right, recipe: recipe))
        root.addChildNode(nose(recipe: recipe))
        root.addChildNode(mouth(recipe: recipe))

        if let facialHairStyle = recipe.hair.facialHair, facialHairStyle != .none {
            root.addChildNode(facialHair(facialHairStyle, recipe: recipe))
        }

        for accessory in recipe.accessories {
            root.addChildNode(accessoryNode(accessory, recipe: recipe))
        }

        addLighting(to: scene)
        addCamera(to: scene)
        return scene
    }

    private func face(recipe: AvatarRecipe) -> SCNNode {
        let geometry = AvatarFaceMeshBuilder().makeFaceGeometry(recipe: recipe)
        geometry.materials = [material(color: palette.skin(for: recipe), roughness: recipe.skin.roughness)]

        let node = SCNNode(geometry: geometry)
        node.name = "skin"
        return node
    }

    private func hair(recipe: AvatarRecipe) -> SCNNode {
        let container = SCNNode()
        container.name = "hair"

        guard recipe.hair.style != .bald else {
            let shine = node(
                name: "hair",
                geometry: SCNSphere(radius: 0.16),
                color: palette.hair(for: recipe)
            )
            shine.position = SCNVector3(0, 0.72, 0.12)
            shine.scale = SCNVector3(1.6, 0.22, 0.55)
            container.addChildNode(shine)
            return container
        }

        let cap = node(
            name: "hair",
            geometry: SCNSphere(radius: 1),
            color: palette.hair(for: recipe)
        )
        cap.position = SCNVector3(0, 0.33, -0.08)
        cap.scale = hairCapScale(for: recipe)
        cap.eulerAngles.x = -0.12
        container.addChildNode(cap)

        let fringe = hairFringe(recipe: recipe)
        container.addChildNode(fringe)

        switch recipe.hair.style {
        case .bob:
            container.addChildNode(sideHair(x: -0.84, length: 0.76, recipe: recipe))
            container.addChildNode(sideHair(x: 0.84, length: 0.76, recipe: recipe))
        case .long:
            container.addChildNode(sideHair(x: -0.9, length: 1.18, recipe: recipe))
            container.addChildNode(sideHair(x: 0.9, length: 1.18, recipe: recipe))
            container.addChildNode(backHair(length: 1.35, recipe: recipe))
        case .ponytail:
            container.addChildNode(backHair(length: 0.8, recipe: recipe))
            let tail = node(
                name: "hair",
                geometry: SCNCapsule(capRadius: 0.13, height: 0.92),
                color: palette.hair(for: recipe)
            )
            tail.position = SCNVector3(0, -0.04, -0.92)
            tail.eulerAngles.x = 0.42
            container.addChildNode(tail)
        case .curly, .wavy:
            addHairClusters(to: container, recipe: recipe)
        case .short, .buzz, .bald:
            break
        }

        return container
    }

    private func hairFringe(recipe: AvatarRecipe) -> SCNNode {
        let fringe = SCNNode()
        fringe.name = "hairFringe"

        let count: Int
        let height: CGFloat
        switch recipe.hair.style {
        case .buzz:
            count = 5
            height = 0.12
        case .short:
            count = 6
            height = 0.2
        case .bob, .long, .ponytail:
            count = 7
            height = 0.28
        case .curly, .wavy:
            count = 8
            height = 0.24
        case .bald:
            count = 0
            height = 0
        }

        guard count > 0 else {
            return fringe
        }

        for index in 0..<count {
            let progress = Float(index) / Float(max(count - 1, 1))
            let x = (progress - 0.5) * 1.15
            let strand = node(
                name: "hair",
                geometry: SCNCapsule(capRadius: 0.045, height: height),
                color: palette.hair(for: recipe)
            )
            strand.position = SCNVector3(x, 0.58 - abs(x) * 0.08, 0.68)
            strand.eulerAngles.x = 1.05
            strand.eulerAngles.z = -x * 0.3
            fringe.addChildNode(strand)
        }

        return fringe
    }

    private func sideHair(x: Float, length: CGFloat, recipe: AvatarRecipe) -> SCNNode {
        let hair = node(
            name: "hair",
            geometry: SCNCapsule(capRadius: 0.12, height: length),
            color: palette.hair(for: recipe)
        )
        hair.position = SCNVector3(x, 0.02 - Float(length) * 0.18, 0.05)
        hair.eulerAngles.z = x < 0 ? -0.08 : 0.08
        return hair
    }

    private func backHair(length: CGFloat, recipe: AvatarRecipe) -> SCNNode {
        let hair = node(
            name: "hair",
            geometry: SCNCapsule(capRadius: 0.34, height: length),
            color: palette.hair(for: recipe)
        )
        hair.position = SCNVector3(0, -0.02 - Float(length) * 0.18, -0.72)
        hair.scale = SCNVector3(1.15, 1, 0.55)
        return hair
    }

    private func addHairClusters(to container: SCNNode, recipe: AvatarRecipe) {
        let positions: [SCNVector3] = [
            SCNVector3(-0.62, 0.46, 0.34),
            SCNVector3(-0.32, 0.66, 0.44),
            SCNVector3(0.02, 0.72, 0.48),
            SCNVector3(0.36, 0.64, 0.42),
            SCNVector3(0.64, 0.42, 0.3),
            SCNVector3(-0.78, 0.14, 0.12),
            SCNVector3(0.78, 0.14, 0.12)
        ]

        for (index, position) in positions.enumerated() {
            let curl = node(
                name: "hair",
                geometry: SCNSphere(radius: recipe.hair.style == .curly ? 0.18 : 0.14),
                color: palette.hair(for: recipe)
            )
            curl.position = position
            let squash = index.isMultiple(of: 2) ? Float(0.82) : Float(1.08)
            curl.scale = SCNVector3(1.15, squash, 0.92)
            container.addChildNode(curl)
        }
    }

    private func eye(name: String, side: AvatarSide, recipe: AvatarRecipe) -> SCNNode {
        let eyeSize = Float(0.82 + recipe.eyes.size * 0.42)
        let eyeHeight = eyeHeight(for: recipe.eyes.shape)
        let eyeWidth = eyeWidth(for: recipe.eyes.shape)
        let spacing = Float(0.25 + recipe.eyes.spacing * 0.18)
        let x = side.sign * spacing
        let width = CGFloat(0.22 * eyeWidth * eyeSize)
        let height = CGFloat(0.12 * eyeHeight * eyeSize)

        let base = SCNBox(width: width, height: height, length: 0.038, chamferRadius: height * 0.42)
        let blink = SCNBox(width: width, height: max(height * 0.18, 0.014), length: 0.038, chamferRadius: height * 0.18)
        blink.name = side == .left ? "blink_L" : "blink_R"

        let eyeNode = node(name: name, geometry: base, color: palette.eye(for: recipe))
        eyeNode.position = SCNVector3(x, 0.16, 0.84)
        eyeNode.eulerAngles.z = eyeTilt(for: recipe.eyes.shape, side: side)
        eyeNode.morpher = SCNMorpher()
        eyeNode.morpher?.targets = [blink]

        let catchlight = node(
            name: "\(name)Catchlight",
            geometry: SCNSphere(radius: 0.022),
            color: UIColor.white.withAlphaComponent(0.88)
        )
        catchlight.position = SCNVector3(0.035, 0.035, 0.1)
        catchlight.scale = SCNVector3(1, 1, 0.25)
        eyeNode.addChildNode(catchlight)

        return eyeNode
    }

    private func cheek(name: String, side: AvatarSide, recipe: AvatarRecipe) -> SCNNode {
        let fullness = CGFloat(0.08 + recipe.face.cheekFullness * 0.08)
        let base = SCNSphere(radius: fullness)
        base.segmentCount = 24
        let squint = SCNSphere(radius: fullness * 1.14)
        squint.segmentCount = 24
        squint.name = side == .left ? "cheek_squint_L" : "cheek_squint_R"

        let cheek = node(
            name: name,
            geometry: base,
            color: palette.skin(for: recipe).mixed(with: UIColor(red: 1, green: 0.46, blue: 0.42, alpha: 1), amount: 0.1)
        )
        cheek.position = SCNVector3(side.sign * 0.34, -0.19, 0.82)
        cheek.scale = SCNVector3(1.25, 0.72, 0.22)
        cheek.opacity = 0.72
        cheek.morpher = SCNMorpher()
        cheek.morpher?.targets = [squint]
        return cheek
    }

    private func brow(name: String, side: AvatarSide, recipe: AvatarRecipe) -> SCNNode {
        let width = CGFloat(0.25 + recipe.eyes.size * 0.09)
        let height = CGFloat(0.035 + recipe.brows.thickness * 0.045)
        let base = SCNBox(width: width, height: height, length: 0.035, chamferRadius: height * 0.35)
        let raised = SCNBox(width: width, height: height * 1.3, length: 0.035, chamferRadius: height * 0.35)
        raised.name = side == .left ? "brow_up_L" : "brow_up_R"

        let spacing = Float(0.25 + recipe.eyes.spacing * 0.18)
        let node = node(name: name, geometry: base, color: palette.brow(for: recipe))
        node.position = SCNVector3(side.sign * spacing, 0.35, 0.82)
        node.eulerAngles.z = browTilt(for: recipe.brows.shape, side: side)
        node.scale.y = browCurveScale(for: recipe.brows.shape)
        node.morpher = SCNMorpher()
        node.morpher?.targets = [raised]
        return node
    }

    private func nose(recipe: AvatarRecipe) -> SCNNode {
        let width = CGFloat(0.07 + recipe.nose.width * 0.06)
        let length = CGFloat(0.2 + recipe.nose.length * 0.16)
        let height = CGFloat(noseHeight(for: recipe.nose.style))
        let geometry = SCNCone(topRadius: width * 0.34, bottomRadius: width, height: length)
        geometry.radialSegmentCount = 24
        let noseNode = node(name: "nose", geometry: geometry, color: palette.skin(for: recipe).adjustedBrightness(0.04))
        noseNode.position = SCNVector3(0, -0.05, 0.91 + Float(height))
        noseNode.eulerAngles.x = .pi / 2

        let tip = node(
            name: "noseTip",
            geometry: SCNSphere(radius: width * noseTipScale(for: recipe.nose.style)),
            color: palette.skin(for: recipe).adjustedBrightness(0.05)
        )
        tip.position = SCNVector3(0, -Float(length) * 0.48, 0)
        tip.scale = SCNVector3(1.05, 0.75, 0.9)
        noseNode.addChildNode(tip)

        return noseNode
    }

    private func mouth(recipe: AvatarRecipe) -> SCNNode {
        let width = CGFloat(0.28 + recipe.mouth.width * 0.28)
        let fullness = CGFloat(0.035 + recipe.mouth.fullness * 0.07)
        let height = mouthHeight(for: recipe.mouth.style, fullness: fullness)
        let base = SCNCapsule(capRadius: height, height: width)
        let jawOpen = SCNCapsule(capRadius: height * 1.12, height: width * 0.86)
        let smileLeft = SCNCapsule(capRadius: height * 0.92, height: width * 1.06)
        let smileRight = SCNCapsule(capRadius: height * 0.92, height: width * 1.06)
        let funnel = SCNCapsule(capRadius: height * 1.35, height: width * 0.52)
        let pucker = SCNCapsule(capRadius: height * 1.12, height: width * 0.42)
        jawOpen.name = "jaw_open"
        smileLeft.name = "smile_L"
        smileRight.name = "smile_R"
        funnel.name = "mouth_funnel"
        pucker.name = "mouth_pucker"

        let mouthNode = node(name: "mouth", geometry: base, color: mouthColor(for: recipe))
        mouthNode.position = SCNVector3(0, -0.42, 0.84)
        mouthNode.eulerAngles.z = .pi / 2
        mouthNode.scale.y = mouthVerticalScale(for: recipe.mouth.style)
        mouthNode.morpher = SCNMorpher()
        mouthNode.morpher?.targets = [jawOpen, smileLeft, smileRight, funnel, pucker]

        let lowerLip = node(
            name: "lowerLip",
            geometry: SCNCapsule(capRadius: height * 0.7, height: width * 0.72),
            color: mouthColor(for: recipe).adjustedBrightness(0.08)
        )
        lowerLip.position = SCNVector3(0, -0.05, -0.006)
        lowerLip.eulerAngles.z = .pi / 2
        mouthNode.addChildNode(lowerLip)

        return mouthNode
    }

    private func facialHair(_ facialHair: FacialHair, recipe: AvatarRecipe) -> SCNNode {
        let container = SCNNode()
        container.name = "facialHair"
        let color = palette.hair(for: recipe).adjustedBrightness(-0.04)

        switch facialHair {
        case .stubble:
            for x in stride(from: -0.42 as Float, through: 0.42, by: 0.14) {
                let dot = node(name: "facialHair", geometry: SCNSphere(radius: 0.025), color: color.withAlphaComponent(0.72))
                dot.position = SCNVector3(x, -0.55 + abs(x) * 0.18, 0.88)
                dot.scale = SCNVector3(1, 0.65, 0.35)
                container.addChildNode(dot)
            }
        case .mustache:
            container.addChildNode(mustacheHalf(side: .left, color: color))
            container.addChildNode(mustacheHalf(side: .right, color: color))
        case .beard:
            container.addChildNode(mustacheHalf(side: .left, color: color))
            container.addChildNode(mustacheHalf(side: .right, color: color))
            let beard = node(name: "facialHair", geometry: SCNSphere(radius: 0.36), color: color.withAlphaComponent(0.86))
            beard.position = SCNVector3(0, -0.62, 0.66)
            beard.scale = SCNVector3(1.55, 0.78, 0.26)
            container.addChildNode(beard)
        case .none:
            break
        }

        return container
    }

    private func mustacheHalf(side: AvatarSide, color: UIColor) -> SCNNode {
        let mustache = node(
            name: "facialHair",
            geometry: SCNCapsule(capRadius: 0.055, height: 0.34),
            color: color
        )
        mustache.position = SCNVector3(side.sign * 0.15, -0.31, 0.9)
        mustache.eulerAngles.z = side == .left ? -1.24 : 1.24
        mustache.scale = SCNVector3(1, 0.72, 0.45)
        return mustache
    }

    private func accessoryNode(_ accessory: AvatarRecipe.Accessory, recipe: AvatarRecipe) -> SCNNode {
        switch accessory.type {
        case .glasses:
            return glasses(colorHex: accessory.colorHex)
        case .earrings:
            return earrings(colorHex: accessory.colorHex, recipe: recipe)
        case .hat:
            return hat(colorHex: accessory.colorHex, recipe: recipe)
        }
    }

    private func glasses(colorHex: String?) -> SCNNode {
        let container = SCNNode()
        container.name = "glasses"
        let color = UIColor(hexString: colorHex ?? "#222222") ?? .black

        for side in [AvatarSide.left, .right] {
            let rim = node(name: "glasses", geometry: SCNTorus(ringRadius: 0.15, pipeRadius: 0.012), color: color)
            rim.position = SCNVector3(side.sign * 0.33, 0.15, 0.86)
            rim.scale = SCNVector3(1, 0.74, 1)
            container.addChildNode(rim)

            let temple = node(name: "glassesArm", geometry: SCNBox(width: 0.26, height: 0.018, length: 0.018, chamferRadius: 0.006), color: color)
            temple.position = SCNVector3(side.sign * 0.55, 0.15, 0.73)
            temple.eulerAngles.y = side == .left ? -0.35 : 0.35
            container.addChildNode(temple)
        }

        let bridge = node(name: "glasses", geometry: SCNBox(width: 0.24, height: 0.025, length: 0.018, chamferRadius: 0.006), color: color)
        bridge.position = SCNVector3(0, 0.15, 0.86)
        container.addChildNode(bridge)

        return container
    }

    private func earrings(colorHex: String?, recipe: AvatarRecipe) -> SCNNode {
        let container = SCNNode()
        container.name = "earrings"
        let color = UIColor(hexString: colorHex ?? "#E7C66A") ?? UIColor(red: 0.9, green: 0.75, blue: 0.35, alpha: 1)

        for side in [AvatarSide.left, .right] {
            let earring = node(name: "earrings", geometry: SCNTorus(ringRadius: 0.055, pipeRadius: 0.01), color: color)
            earring.position = SCNVector3(side.sign * 0.83, -0.16, 0.16)
            earring.eulerAngles.x = .pi / 2
            container.addChildNode(earring)
        }

        return container
    }

    private func hat(colorHex: String?, recipe: AvatarRecipe) -> SCNNode {
        let container = SCNNode()
        container.name = "hat"
        let color = UIColor(hexString: colorHex ?? "#3E5B7A") ?? UIColor(red: 0.24, green: 0.36, blue: 0.48, alpha: 1)

        let brim = node(name: "hat", geometry: SCNCapsule(capRadius: 0.08, height: 1.08), color: color.adjustedBrightness(-0.04))
        brim.position = SCNVector3(0, 0.64, 0.42)
        brim.eulerAngles.z = .pi / 2
        brim.scale = SCNVector3(1, 0.58, 0.18)
        container.addChildNode(brim)

        let crown = node(name: "hat", geometry: SCNSphere(radius: 0.52), color: color)
        crown.position = SCNVector3(0, 0.82, 0.02)
        crown.scale = SCNVector3(1.2, 0.56, 0.86)
        container.addChildNode(crown)

        return container
    }

    private func addLighting(to scene: SCNScene) {
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 850
        keyLight.position = SCNVector3(-0.9, 2.4, 3.3)
        scene.rootNode.addChildNode(keyLight)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .ambient
        fillLight.light?.intensity = 280
        scene.rootNode.addChildNode(fillLight)
    }

    private func addCamera(to scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 42
        cameraNode.position = SCNVector3(0, 0.03, 4.35)
        scene.rootNode.addChildNode(cameraNode)
    }

    private func node(name: String, geometry: SCNGeometry, color: UIColor) -> SCNNode {
        geometry.firstMaterial = material(color: color)
        let node = SCNNode(geometry: geometry)
        node.name = name
        return node
    }

    private func material(color: UIColor, roughness: Double = 0.68) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.roughness.contents = CGFloat(roughness.clamped(to: 0.18...0.92))
        material.lightingModel = .physicallyBased
        return material
    }

    private func hairCapScale(for recipe: AvatarRecipe) -> SCNVector3 {
        switch recipe.hair.style {
        case .short:
            return SCNVector3(0.94, 0.58, 0.82)
        case .bob:
            return SCNVector3(1.0, 0.78, 0.9)
        case .long, .ponytail:
            return SCNVector3(1.02, 0.88, 0.92)
        case .curly:
            return SCNVector3(1.08, 0.94, 0.94)
        case .wavy:
            return SCNVector3(1.06, 0.88, 0.94)
        case .buzz:
            return SCNVector3(0.88, 0.5, 0.8)
        case .bald:
            return SCNVector3(0.05, 0.05, 0.05)
        }
    }

    private func eyeHeight(for shape: EyeShape) -> Float {
        switch shape {
        case .almond, .hooded:
            return 0.48
        case .round:
            return 0.68
        case .monolid:
            return 0.32
        case .upturned, .downturned:
            return 0.44
        }
    }

    private func eyeWidth(for shape: EyeShape) -> Float {
        switch shape {
        case .round:
            return 0.88
        case .monolid:
            return 1.08
        default:
            return 1
        }
    }

    private func eyeTilt(for shape: EyeShape, side: AvatarSide) -> Float {
        switch shape {
        case .upturned:
            return side.sign * 0.16
        case .downturned:
            return side.sign * -0.16
        default:
            return 0
        }
    }

    private func browTilt(for shape: BrowShape, side: AvatarSide) -> Float {
        switch shape {
        case .softArch:
            return side.sign * 0.12
        case .straight:
            return 0
        case .rounded:
            return side.sign * 0.05
        case .angled:
            return side.sign * 0.22
        }
    }

    private func browCurveScale(for shape: BrowShape) -> Float {
        switch shape {
        case .rounded:
            return 1.22
        case .straight:
            return 0.78
        default:
            return 1
        }
    }

    private func noseHeight(for style: NoseStyle) -> CGFloat {
        switch style {
        case .button:
            return -0.02
        case .soft:
            return 0
        case .straight:
            return 0.02
        case .defined:
            return 0.04
        }
    }

    private func noseTipScale(for style: NoseStyle) -> CGFloat {
        switch style {
        case .button:
            return 1.24
        case .soft:
            return 1.08
        case .straight:
            return 0.92
        case .defined:
            return 0.82
        }
    }

    private func mouthHeight(for style: MouthStyle, fullness: CGFloat) -> CGFloat {
        switch style {
        case .small:
            return fullness * 0.8
        case .wide:
            return fullness * 0.92
        case .full:
            return fullness * 1.25
        case .softSmile:
            return fullness
        }
    }

    private func mouthVerticalScale(for style: MouthStyle) -> Float {
        switch style {
        case .full:
            return 1.18
        case .small:
            return 0.84
        default:
            return 1
        }
    }

    private func mouthColor(for recipe: AvatarRecipe) -> UIColor {
        palette.skin(for: recipe)
            .mixed(with: UIColor(red: 0.56, green: 0.08, blue: 0.16, alpha: 1), amount: 0.48)
            .adjustedBrightness(0.04 + recipe.skin.warmth * 0.05)
    }

    private let palette = AvatarRecipeColorPalette()
}

struct AvatarFaceMeshBuilder {
    func makeFaceGeometry(recipe: AvatarRecipe) -> SCNGeometry {
        let latitudeSegments = 22
        let longitudeSegments = 36
        let model = FaceModel(recipe: recipe)
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var uvs: [CGPoint] = []
        var indices: [Int32] = []

        for latitude in 0...latitudeSegments {
            let v = Float(latitude) / Float(latitudeSegments)
            let theta = -.pi / 2 + Float.pi * v
            for longitude in 0...longitudeSegments {
                let u = Float(longitude) / Float(longitudeSegments)
                let phi = Float.pi * 2 * u
                let raw = SCNVector3(
                    cos(theta) * sin(phi),
                    sin(theta),
                    cos(theta) * cos(phi)
                )
                let vertex = model.project(raw)
                vertices.append(vertex)
                normals.append(raw.normalized)
                uvs.append(CGPoint(x: CGFloat(u), y: CGFloat(1 - v)))
            }
        }

        let stride = longitudeSegments + 1
        for latitude in 0..<latitudeSegments {
            for longitude in 0..<longitudeSegments {
                let topLeft = Int32(latitude * stride + longitude)
                let topRight = Int32(topLeft + 1)
                let bottomLeft = Int32((latitude + 1) * stride + longitude)
                let bottomRight = Int32(bottomLeft + 1)
                indices.append(contentsOf: [topLeft, bottomLeft, topRight, topRight, bottomLeft, bottomRight])
            }
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let uvSource = SCNGeometrySource(textureCoordinates: uvs)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: [element])
        geometry.name = "skin"
        return geometry
    }

    private struct FaceModel {
        let recipe: AvatarRecipe

        func project(_ raw: SCNVector3) -> SCNVector3 {
            let y = raw.y
            let vertical = (y + 1) / 2
            let lowerFace = max(0, -y)
            let upperFace = max(0, y)
            let cheekBand = max(0, 1 - abs(y + 0.12) * 2.6)

            var width = baseWidth
            width *= 1 + Float(recipe.face.cheekFullness) * 0.14 * cheekBand
            width *= 1 + Float(recipe.face.jawWidth - 0.5) * 0.22 * lowerFace
            width *= 1 - Float(recipe.face.roundness - 0.5) * 0.12 * upperFace
            width *= shapeWidthMultiplier(y: y)

            let height = baseHeight * shapeHeightMultiplier(y: y)
            var depth = baseDepth
            depth *= 1 + Float(recipe.face.roundness - 0.5) * 0.14
            depth *= 1 + Float(recipe.face.cheekFullness - 0.5) * 0.12 * cheekBand

            var projected = SCNVector3(raw.x * width, y * height, raw.z * depth)
            projected.y += vertical * 0.06
            projected.z += 0.02 * cheekBand - 0.04 * lowerFace
            return projected
        }

        private var baseWidth: Float { 0.78 + Float(recipe.face.roundness) * 0.08 }
        private var baseHeight: Float { 1.02 + Float(recipe.face.roundness) * -0.04 }
        private var baseDepth: Float { 0.72 }

        private func shapeWidthMultiplier(y: Float) -> Float {
            let lowerFace = max(0, -y)
            let upperFace = max(0, y)
            switch recipe.face.shape {
            case .round:
                return 1.04 - 0.06 * upperFace
            case .oval:
                return 0.98 + 0.04 * (1 - abs(y))
            case .heart:
                return 1.07 * (1 + 0.06 * upperFace) * (1 - 0.12 * lowerFace)
            case .square:
                return 1.02 + 0.08 * lowerFace
            case .long:
                return 0.92 + 0.02 * (1 - abs(y))
            }
        }

        private func shapeHeightMultiplier(y: Float) -> Float {
            switch recipe.face.shape {
            case .long:
                return 1.1
            case .round:
                return 0.96
            default:
                return 1
            }
        }
    }
}

struct AvatarRecipeGeometryApplier {
    func apply(recipe: AvatarRecipe, to scene: SCNScene) {
        let metrics = AvatarRecipeNodeMetrics(recipe: recipe)

        scene.rootNode.enumerateChildNodes { node, _ in
            guard let name = node.name else {
                return
            }

            switch name {
            case "avatarRoot":
                break
            case "skin":
                applySkin(recipe: recipe, metrics: metrics, to: node)
            case "hair":
                applyHair(recipe: recipe, metrics: metrics, to: node)
            case "leftEye":
                applyEye(recipe: recipe, metrics: metrics, side: .left, to: node)
            case "rightEye":
                applyEye(recipe: recipe, metrics: metrics, side: .right, to: node)
            case "leftBrow":
                applyBrow(recipe: recipe, metrics: metrics, side: .left, to: node)
            case "rightBrow":
                applyBrow(recipe: recipe, metrics: metrics, side: .right, to: node)
            case "nose":
                applyNose(recipe: recipe, metrics: metrics, to: node)
            case "mouth":
                applyMouth(recipe: recipe, metrics: metrics, to: node)
            case "glasses":
                node.scale = SCNVector3(metrics.eyeSpacingScale, 1, 1)
            default:
                break
            }
        }
    }

    private func applySkin(recipe: AvatarRecipe, metrics: AvatarRecipeNodeMetrics, to node: SCNNode) {
        node.scale = SCNVector3(metrics.faceWidthScale, metrics.faceHeightScale, metrics.faceDepthScale)

        if node.geometry is SCNSphere {
            node.geometry = AvatarFaceMeshBuilder().makeFaceGeometry(recipe: recipe)
        }
    }

    private func applyHair(recipe: AvatarRecipe, metrics: AvatarRecipeNodeMetrics, to node: SCNNode) {
        node.scale = metrics.hairScale
        node.position.y += metrics.hairYOffset
    }

    private func applyEye(recipe: AvatarRecipe, metrics: AvatarRecipeNodeMetrics, side: AvatarSide, to node: SCNNode) {
        node.position = SCNVector3(side.sign * metrics.eyeSpacing, 0.16, 0.84)
        node.scale = SCNVector3(metrics.eyeWidth, metrics.eyeHeight, 0.24)
        node.eulerAngles.z = metrics.eyeTilt * side.sign
    }

    private func applyBrow(recipe: AvatarRecipe, metrics: AvatarRecipeNodeMetrics, side: AvatarSide, to node: SCNNode) {
        node.position = SCNVector3(side.sign * metrics.eyeSpacing, 0.35, 0.82)
        node.scale = SCNVector3(metrics.browWidth, metrics.browHeight, 1)
        node.eulerAngles.z = metrics.browTilt * side.sign
    }

    private func applyNose(recipe: AvatarRecipe, metrics: AvatarRecipeNodeMetrics, to node: SCNNode) {
        node.scale = SCNVector3(metrics.noseWidth, metrics.noseLength, metrics.noseWidth)
        node.position = SCNVector3(0, -0.05, 0.91 + metrics.noseProjection)
    }

    private func applyMouth(recipe: AvatarRecipe, metrics: AvatarRecipeNodeMetrics, to node: SCNNode) {
        node.scale = SCNVector3(metrics.mouthWidth, metrics.mouthHeight, 1)
        node.position = SCNVector3(0, -0.42, 0.84)
    }
}

struct AvatarRecipeNodeMetrics {
    let faceWidthScale: Float
    let faceHeightScale: Float
    let faceDepthScale: Float
    let hairScale: SCNVector3
    let hairYOffset: Float
    let eyeSpacing: Float
    let eyeSpacingScale: Float
    let eyeWidth: Float
    let eyeHeight: Float
    let eyeTilt: Float
    let browWidth: Float
    let browHeight: Float
    let browTilt: Float
    let noseWidth: Float
    let noseLength: Float
    let noseProjection: Float
    let mouthWidth: Float
    let mouthHeight: Float

    init(recipe: AvatarRecipe) {
        faceWidthScale = 0.92 + Float(recipe.face.jawWidth) * 0.22 + Self.faceShapeWidthAdjustment(recipe.face.shape)
        faceHeightScale = 0.94 + Float(recipe.face.roundness) * 0.08 + Self.faceShapeHeightAdjustment(recipe.face.shape)
        faceDepthScale = 0.92 + Float(recipe.face.cheekFullness) * 0.16

        hairScale = Self.hairScale(for: recipe.hair.style)
        hairYOffset = recipe.hair.style == .bald ? -0.08 : 0

        eyeSpacing = 0.25 + Float(recipe.eyes.spacing) * 0.18
        eyeSpacingScale = 0.92 + Float(recipe.eyes.spacing) * 0.22
        eyeWidth = (0.82 + Float(recipe.eyes.size) * 0.42) * Self.eyeWidth(for: recipe.eyes.shape)
        eyeHeight = (0.82 + Float(recipe.eyes.size) * 0.42) * Self.eyeHeight(for: recipe.eyes.shape)
        eyeTilt = Self.eyeTilt(for: recipe.eyes.shape)

        browWidth = 0.9 + Float(recipe.eyes.size) * 0.24
        browHeight = 0.72 + Float(recipe.brows.thickness) * 0.62
        browTilt = Self.browTilt(for: recipe.brows.shape)

        noseWidth = 0.72 + Float(recipe.nose.width) * 0.56
        noseLength = 0.78 + Float(recipe.nose.length) * 0.58
        noseProjection = Self.noseProjection(for: recipe.nose.style)

        mouthWidth = 0.78 + Float(recipe.mouth.width) * 0.72 + Self.mouthWidthAdjustment(for: recipe.mouth.style)
        mouthHeight = 0.78 + Float(recipe.mouth.fullness) * 0.68 + Self.mouthHeightAdjustment(for: recipe.mouth.style)
    }

    private static func faceShapeWidthAdjustment(_ shape: FaceShape) -> Float {
        switch shape {
        case .round:
            return 0.04
        case .heart:
            return 0.02
        case .square:
            return 0.07
        case .long:
            return -0.07
        case .oval:
            return 0
        }
    }

    private static func faceShapeHeightAdjustment(_ shape: FaceShape) -> Float {
        switch shape {
        case .long:
            return 0.12
        case .round:
            return -0.04
        default:
            return 0
        }
    }

    private static func hairScale(for style: HairStyle) -> SCNVector3 {
        switch style {
        case .short:
            return SCNVector3(0.96, 0.62, 0.84)
        case .bob:
            return SCNVector3(1.02, 0.84, 0.92)
        case .long:
            return SCNVector3(1.06, 1.18, 0.94)
        case .curly:
            return SCNVector3(1.12, 1.02, 0.98)
        case .wavy:
            return SCNVector3(1.08, 0.94, 0.96)
        case .buzz:
            return SCNVector3(0.9, 0.48, 0.8)
        case .bald:
            return SCNVector3(0.08, 0.08, 0.08)
        case .ponytail:
            return SCNVector3(1.04, 0.9, 0.94)
        }
    }

    private static func eyeHeight(for shape: EyeShape) -> Float {
        switch shape {
        case .round:
            return 0.68
        case .monolid:
            return 0.32
        case .hooded:
            return 0.4
        default:
            return 0.5
        }
    }

    private static func eyeWidth(for shape: EyeShape) -> Float {
        switch shape {
        case .round:
            return 0.9
        case .monolid:
            return 1.1
        default:
            return 1
        }
    }

    private static func eyeTilt(for shape: EyeShape) -> Float {
        switch shape {
        case .upturned:
            return 0.16
        case .downturned:
            return -0.16
        default:
            return 0
        }
    }

    private static func browTilt(for shape: BrowShape) -> Float {
        switch shape {
        case .softArch:
            return 0.12
        case .straight:
            return 0
        case .rounded:
            return 0.05
        case .angled:
            return 0.22
        }
    }

    private static func noseProjection(for style: NoseStyle) -> Float {
        switch style {
        case .button:
            return -0.02
        case .soft:
            return 0
        case .straight:
            return 0.02
        case .defined:
            return 0.04
        }
    }

    private static func mouthWidthAdjustment(for style: MouthStyle) -> Float {
        switch style {
        case .small:
            return -0.1
        case .wide:
            return 0.14
        default:
            return 0
        }
    }

    private static func mouthHeightAdjustment(for style: MouthStyle) -> Float {
        switch style {
        case .full:
            return 0.12
        case .small:
            return -0.06
        default:
            return 0
        }
    }
}

enum AvatarSide {
    case left
    case right

    var sign: Float {
        switch self {
        case .left:
            return -1
        case .right:
            return 1
        }
    }
}

struct AvatarRecipeColorPalette {
    func skin(for recipe: AvatarRecipe) -> UIColor {
        (UIColor(hexString: recipe.skin.toneHex) ?? UIColor(red: 0.91, green: 0.73, blue: 0.57, alpha: 1))
            .adjustedWarmth(recipe.skin.warmth)
    }

    func hair(for recipe: AvatarRecipe) -> UIColor {
        UIColor(hexString: recipe.hair.colorHex) ?? UIColor(red: 0.14, green: 0.09, blue: 0.06, alpha: 1)
    }

    func eye(for recipe: AvatarRecipe) -> UIColor {
        UIColor(hexString: recipe.eyes.colorHex) ?? .black
    }

    func brow(for recipe: AvatarRecipe) -> UIColor {
        UIColor(hexString: recipe.brows.colorHex) ?? hair(for: recipe)
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        let trimmed = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmed.count == 6, let value = Int(trimmed, radix: 16) else {
            return nil
        }

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    func adjustedBrightness(_ delta: Double) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }

        return UIColor(
            hue: hue,
            saturation: saturation,
            brightness: min(max(brightness + CGFloat(delta), 0), 1),
            alpha: alpha
        )
    }

    func adjustedWarmth(_ warmth: Double) -> UIColor {
        mixed(with: UIColor(red: 1, green: 0.62, blue: 0.36, alpha: 1), amount: (warmth - 0.5).clamped(to: -0.5...0.5) * 0.18)
    }

    func mixed(with color: UIColor, amount: Double) -> UIColor {
        let clampedAmount = CGFloat(abs(amount).clamped(to: 0...1))
        let target = amount >= 0 ? color : UIColor(red: 0.72, green: 0.84, blue: 1, alpha: 1)

        var redA: CGFloat = 0
        var greenA: CGFloat = 0
        var blueA: CGFloat = 0
        var alphaA: CGFloat = 0
        var redB: CGFloat = 0
        var greenB: CGFloat = 0
        var blueB: CGFloat = 0
        var alphaB: CGFloat = 0

        getRed(&redA, green: &greenA, blue: &blueA, alpha: &alphaA)
        target.getRed(&redB, green: &greenB, blue: &blueB, alpha: &alphaB)

        return UIColor(
            red: redA + (redB - redA) * clampedAmount,
            green: greenA + (greenB - greenA) * clampedAmount,
            blue: blueA + (blueB - blueA) * clampedAmount,
            alpha: alphaA + (alphaB - alphaA) * clampedAmount
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension SCNVector3 {
    var normalized: SCNVector3 {
        let length = sqrt(x * x + y * y + z * z)
        guard length > 0 else {
            return self
        }
        return SCNVector3(x / length, y / length, z / length)
    }
}
