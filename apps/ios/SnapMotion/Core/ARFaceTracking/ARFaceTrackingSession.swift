import ARKit
import CoreImage
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

    static var isFaceTrackingSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    var isSupported: Bool {
        Self.isFaceTrackingSupported
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
        let currentFrame = session.currentFrame
        let timestamp = currentFrame?.timestamp ?? Date().timeIntervalSince1970
        let lightEstimate = currentFrame?.lightEstimate.map { Double($0.ambientIntensity) }

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

extension ARFaceTrackingSession {
    func captureCurrentFrameImage(slot: CaptureSlot) throws -> CapturedImageSample {
        guard let frame = session.currentFrame else {
            throw ARFaceTrackingSessionError.missingCurrentFrame
        }

        let image = CIImage(cvPixelBuffer: frame.capturedImage)
        let sharpness = ImageSharpnessEvaluator().score(ciImage: image)
        let url = try CaptureFrameImageWriter().writeJPEG(ciImage: image, slot: slot, timestamp: frame.timestamp)
        return CapturedImageSample(localURL: url, sharpness: sharpness)
    }
}

struct CapturedImageSample {
    let localURL: URL
    let sharpness: Double
}

enum ARFaceTrackingSessionError: Error, LocalizedError {
    case missingCurrentFrame

    var errorDescription: String? {
        switch self {
        case .missingCurrentFrame:
            return "No camera frame is available yet."
        }
    }
}
