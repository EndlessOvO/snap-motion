import ARKit
import Foundation

@MainActor
final class ARFaceTrackingSession: NSObject, ObservableObject {
    @Published private(set) var latestFrame: FaceTrackingFrame?
    @Published private(set) var errorMessage: String?

    let session = ARSession()

    override init() {
        super.init()
        session.delegate = self
    }

    var isSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    func start() {
        guard isSupported else {
            errorMessage = "Face tracking requires a TrueDepth front camera."
            return
        }

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
    }
}

extension ARFaceTrackingSession: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            return
        }

        let blendShapes = Dictionary(
            uniqueKeysWithValues: FaceBlendShape.allCases.map { shape in
                let value = faceAnchor.blendShapes[shape.arkitLocation]?.doubleValue ?? 0
                return (shape, value.clamped(to: 0...1))
            }
        )

        let transform = faceAnchor.transform
        let timestamp = session.currentFrame?.timestamp ?? Date().timeIntervalSince1970
        let lightEstimate = session.currentFrame?.lightEstimate?.ambientIntensity

        Task { @MainActor in
            latestFrame = FaceTrackingFrame(
                timestamp: timestamp,
                pose: FacePoseEstimator().estimatePose(from: transform),
                blendShapes: blendShapes,
                lightEstimate: lightEstimate
            )
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
