import Foundation

struct LocalAvatarRecipeFactory {
    func makeRecipe(from manifest: CaptureManifest, deviceID: String) -> AvatarRecipe {
        let quality = averageQuality(in: manifest)
        let poseRange = poseRange(in: manifest)
        let expression = expressionPeaks(in: manifest)
        let deviceSeed = stableHash(deviceID)
        let seed = deviceSeed ^ manifest.captureSlots.count

        return AvatarRecipe(
            schemaVersion: 1,
            avatarID: "avatar_local_\(deviceSeed)_\(Int(manifest.createdAt.timeIntervalSince1970))",
            displayName: "Local Snap Friend",
            rig: AvatarRecipe.Rig(
                templateID: "procedural_cute_avatar_v1",
                morphCalibration: [
                    "blink_L": calibration(for: expression.blink, fallback: 1.2),
                    "blink_R": calibration(for: expression.blink, fallback: 1.2),
                    "jaw_open": calibration(for: expression.mouth, fallback: 1.25),
                    "smile_L": calibration(for: expression.smile, fallback: 1.15),
                    "smile_R": calibration(for: expression.smile, fallback: 1.15),
                    "brow_up_L": 1,
                    "brow_up_R": 1,
                    "mouth_funnel": 1,
                    "mouth_pucker": 1,
                    "cheek_squint_L": 1,
                    "cheek_squint_R": 1
                ]
            ),
            face: AvatarRecipe.Face(
                shape: faceShape(seed: seed, poseRange: poseRange),
                roundness: clamp(0.62 + (quality * 0.18) - (poseRange.yaw * 0.002)),
                jawWidth: clamp(0.38 + (poseRange.yaw * 0.004)),
                cheekFullness: clamp(0.58 + (quality * 0.22))
            ),
            skin: AvatarRecipe.Skin(
                toneHex: skinTone(seed: seed, quality: quality),
                warmth: clamp(0.5 + (quality * 0.18)),
                roughness: clamp(0.48 - (quality * 0.18))
            ),
            eyes: AvatarRecipe.Eyes(
                shape: eyeShape(seed: seed),
                colorHex: eyeColor(seed: seed),
                size: clamp(0.54 + (expression.blink * 0.1)),
                spacing: clamp(0.48 + (poseRange.yaw * 0.001))
            ),
            brows: AvatarRecipe.Brows(
                shape: browShape(seed: seed),
                colorHex: hairColor(seed: seed),
                thickness: clamp(0.48 + (expression.smile * 0.14))
            ),
            nose: AvatarRecipe.Nose(
                style: noseStyle(seed: seed),
                width: clamp(0.42 + (poseRange.yaw * 0.002)),
                length: clamp(0.45 + (poseRange.pitch * 0.003))
            ),
            mouth: AvatarRecipe.Mouth(
                style: expression.smile > 0.4 ? .softSmile : .small,
                width: clamp(0.48 + (expression.smile * 0.18)),
                fullness: clamp(0.42 + (expression.mouth * 0.16))
            ),
            hair: AvatarRecipe.Hair(
                style: hairStyle(seed: seed),
                colorHex: hairColor(seed: seed),
                facialHair: FacialHair.none
            ),
            accessories: [],
            materials: AvatarRecipe.Materials(
                skinTextureURL: URL(fileURLWithPath: "/snap-motion/generated/local-skin-\(seed % 5).png"),
                hairTextureURL: URL(fileURLWithPath: "/snap-motion/generated/local-hair-\(seed % 5).png"),
                extraTextureURLs: []
            )
        )
    }

    private func averageQuality(in manifest: CaptureManifest) -> Double {
        guard !manifest.captureSlots.isEmpty else {
            return 0.5
        }

        let total = manifest.captureSlots.reduce(0) { partial, frame in
            partial + frame.quality.total
        }
        return clamp(total / Double(manifest.captureSlots.count))
    }

    private func poseRange(in manifest: CaptureManifest) -> (yaw: Double, pitch: Double) {
        let yaw = manifest.captureSlots.map { abs($0.pose.yaw) }.max() ?? 0
        let pitch = manifest.captureSlots.map { abs($0.pose.pitch) }.max() ?? 0
        return (yaw, pitch)
    }

    private func expressionPeaks(in manifest: CaptureManifest) -> (blink: Double, mouth: Double, smile: Double) {
        let blink = manifest.captureSlots
            .filter { $0.slot == .blink }
            .map(\.quality.expressionMatch)
            .max() ?? 0
        let mouth = manifest.captureSlots
            .filter { $0.slot == .mouthOpen }
            .map(\.quality.expressionMatch)
            .max() ?? 0
        let smile = manifest.captureSlots
            .filter { $0.slot == .smile }
            .map(\.quality.expressionMatch)
            .max() ?? 0
        return (blink, mouth, smile)
    }

    private func calibration(for value: Double, fallback: Double) -> Double {
        clamp(fallback + ((1 - value) * 0.35), minimum: 0.8, maximum: 1.8)
    }

    private func faceShape(seed: Int, poseRange: (yaw: Double, pitch: Double)) -> FaceShape {
        if poseRange.pitch > 20 {
            return .long
        }
        if poseRange.yaw > 30 {
            return .oval
        }
        return [.round, .oval, .heart, .square][seed % 4]
    }

    private func eyeShape(seed: Int) -> EyeShape {
        [.almond, .round, .hooded, .upturned][seed % 4]
    }

    private func browShape(seed: Int) -> BrowShape {
        [.softArch, .straight, .rounded, .angled][seed % 4]
    }

    private func noseStyle(seed: Int) -> NoseStyle {
        [.soft, .button, .straight, .defined][seed % 4]
    }

    private func hairStyle(seed: Int) -> HairStyle {
        [.short, .bob, .long, .curly, .wavy, .ponytail][seed % 6]
    }

    private func skinTone(seed: Int, quality: Double) -> String {
        let palette = ["#F1C7A8", "#E9B98F", "#DFA77B", "#C98B62", "#A96F50", "#8F5A42"]
        let offset = quality > 0.75 ? 0 : 1
        return palette[(seed + offset) % palette.count]
    }

    private func eyeColor(seed: Int) -> String {
        ["#3B2418", "#4A2C1A", "#2F3E46", "#24415A", "#5B4A2F"][seed % 5]
    }

    private func hairColor(seed: Int) -> String {
        ["#24170F", "#2B1B12", "#3A261B", "#5A3825", "#161616", "#6B4A33"][seed % 6]
    }

    private func clamp(_ value: Double, minimum: Double = 0, maximum: Double = 1) -> Double {
        min(max(value, minimum), maximum)
    }

    private func stableHash(_ value: String) -> Int {
        let hash = value.unicodeScalars.reduce(UInt64(14_695_981_039_346_656_037)) { result, scalar in
            (result ^ UInt64(scalar.value)) &* 1_099_511_628_211
        }
        return Int(hash % UInt64(Int.max))
    }
}
