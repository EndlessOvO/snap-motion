import ARKit
import CoreImage
import Foundation
import SwiftUI

struct ARFaceCameraView: UIViewRepresentable {
    let currentSlot: CaptureSlot
    let onFrame: (FaceTrackingFrame, Double, URL) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(currentSlot: currentSlot, onFrame: onFrame, onError: onError)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session.delegate = context.coordinator
        view.automaticallyUpdatesLighting = true
        view.backgroundColor = .clear
        startSessionIfSupported(view.session)
        return view
    }

    func updateUIView(_ view: ARSCNView, context: Context) {
        context.coordinator.currentSlot = currentSlot
    }

    static func dismantleUIView(_ view: ARSCNView, coordinator: Coordinator) {
        view.session.pause()
        view.session.delegate = nil
    }

    private func startSessionIfSupported(_ session: ARSession) {
        guard ARFaceTrackingConfiguration.isSupported else {
            onError("Face tracking requires a TrueDepth front camera.")
            return
        }

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ARFaceCameraView {
    final class Coordinator: NSObject, ARSessionDelegate {
        private let onFrame: (FaceTrackingFrame, Double, URL) -> Void
        private let onError: (String) -> Void
        private let sharpnessEvaluator = ImageSharpnessEvaluator()
        private let imageWriter = CaptureFrameImageWriter()
        private var lastFrameTimestamp: TimeInterval = 0
        var currentSlot: CaptureSlot

        init(
            currentSlot: CaptureSlot,
            onFrame: @escaping (FaceTrackingFrame, Double, URL) -> Void,
            onError: @escaping (String) -> Void
        ) {
            self.currentSlot = currentSlot
            self.onFrame = onFrame
            self.onError = onError
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first,
                  let currentFrame = session.currentFrame
            else {
                return
            }

            let blendShapes = Dictionary(
                uniqueKeysWithValues: FaceBlendShape.allCases.map { shape in
                    let value = faceAnchor.blendShapes[shape.arkitLocation]?.doubleValue ?? 0
                    return (shape, value.clamped(to: 0...1))
                }
            )

            let shouldCaptureExpressionPeak = expressionPeak(
                for: currentSlot,
                blendShapes: blendShapes
            ) >= expressionPeakThreshold(for: currentSlot)
            guard shouldCaptureExpressionPeak || currentFrame.timestamp - lastFrameTimestamp >= sampleInterval(for: currentSlot) else {
                return
            }
            lastFrameTimestamp = currentFrame.timestamp

            let faceFrame = FaceTrackingFrame(
                timestamp: currentFrame.timestamp,
                pose: FacePoseEstimator().estimatePose(from: faceAnchor.transform),
                blendShapes: blendShapes,
                lightEstimate: currentFrame.lightEstimate.map { Double($0.ambientIntensity) }
            )
            let image = CIImage(cvPixelBuffer: currentFrame.capturedImage)
            let sharpness = sharpnessEvaluator.score(ciImage: image)

            do {
                let imageURL = try imageWriter.writeJPEG(
                    ciImage: image,
                    slot: currentSlot,
                    timestamp: currentFrame.timestamp
                )
                Task { @MainActor in
                    onFrame(faceFrame, sharpness, imageURL)
                }
            } catch {
                Task { @MainActor in
                    onError(error.localizedDescription)
                }
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            Task { @MainActor in
                onError(error.localizedDescription)
            }
        }

        private func sampleInterval(for slot: CaptureSlot) -> TimeInterval {
            switch slot {
            case .blink:
                return 0.04
            case .mouthOpen, .smile:
                return 0.06
            case .neutralFront, .turnLeft, .turnRight, .lookUp, .lookDown:
                return 0.25
            }
        }

        private func expressionPeak(for slot: CaptureSlot, blendShapes: [FaceBlendShape: Double]) -> Double {
            switch slot {
            case .blink:
                return max(
                    blendShapes[.eyeBlinkLeft] ?? 0,
                    blendShapes[.eyeBlinkRight] ?? 0
                )
            case .mouthOpen:
                return blendShapes[.jawOpen] ?? 0
            case .smile:
                return ((blendShapes[.mouthSmileLeft] ?? 0) + (blendShapes[.mouthSmileRight] ?? 0)) / 2
            case .neutralFront, .turnLeft, .turnRight, .lookUp, .lookDown:
                return 0
            }
        }

        private func expressionPeakThreshold(for slot: CaptureSlot) -> Double {
            switch slot {
            case .blink:
                return 0.16
            case .mouthOpen:
                return 0.18
            case .smile:
                return 0.22
            case .neutralFront, .turnLeft, .turnRight, .lookUp, .lookDown:
                return .greatestFiniteMagnitude
            }
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
