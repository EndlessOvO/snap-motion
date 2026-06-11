import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class FaceEnrollmentViewModel: ObservableObject {
    @Published private(set) var currentSlot: CaptureSlot = .neutralFront
    @Published private(set) var completedSlots: Set<CaptureSlot> = []
    @Published private(set) var qualityMessage: String = "Center your face in the oval."
    @Published private(set) var canContinue: Bool = false
    @Published private(set) var selectedFrames: [CaptureSlot: CaptureManifest.CapturedFrame] = [:]
    @Published private(set) var captureState: CaptureState = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var observedFrameCount: Int = 0
    @Published private(set) var latestQuality: FaceQualityScore?

    private let evaluator = FaceQualityEvaluator()
    private let selector = CaptureFrameSelector()
    private let permissionService: CameraPermissionService
    private let deviceInfoProvider: DeviceInfoProvider
    private let forceFaceTrackingSupport: Bool?
    private let acceptanceThreshold = 0.66
    private let blinkExpressionThreshold = 0.16
    private let mouthExpressionThreshold = 0.18
    private let smileExpressionThreshold = 0.22
    private let blinkFallbackFrameCount = 24
    private let expressionFallbackFrameCount = 30
    private var observedFrameCountBySlot: [CaptureSlot: Int] = [:]
    private var fallbackCandidates: [CaptureSlot: CaptureManifest.CapturedFrame] = [:]

    init(
        permissionService: CameraPermissionService = CameraPermissionService(),
        deviceInfoProvider: DeviceInfoProvider = DeviceInfoProvider(),
        forceFaceTrackingSupport: Bool? = nil
    ) {
        self.permissionService = permissionService
        self.deviceInfoProvider = deviceInfoProvider
        self.forceFaceTrackingSupport = forceFaceTrackingSupport
    }

    var progress: Double {
        Double(completedSlots.count) / Double(CaptureSlot.allCases.count)
    }

    var prompt: String {
        currentSlot.prompt
    }

    var device: CaptureManifest.Device {
        deviceInfoProvider.makeDevice()
    }

    func prepareCapture(isFaceTrackingSupported: Bool) async -> Bool {
        let supported = forceFaceTrackingSupport ?? isFaceTrackingSupported
        guard supported else {
            captureState = .unsupported
            errorMessage = "Face tracking requires a TrueDepth front camera."
            qualityMessage = "Use an iPhone with Face ID to capture enrollment frames."
            return false
        }

        switch permissionService.authorizationStatus() {
        case .authorized:
            captureState = .running
            errorMessage = nil
            return true
        case .notDetermined:
            captureState = .requestingPermission
            let granted = await permissionService.requestAccess()
            captureState = granted ? .running : .permissionDenied
            errorMessage = granted ? nil : "Camera access is required for face enrollment."
            qualityMessage = granted ? qualityMessage : "Enable camera access in Settings to enroll your face."
            return granted
        case .denied, .restricted:
            captureState = .permissionDenied
            errorMessage = "Camera access is required for face enrollment."
            qualityMessage = "Enable camera access in Settings to enroll your face."
            return false
        @unknown default:
            captureState = .failed
            errorMessage = "Camera permission is unavailable."
            return false
        }
    }

    func ingest(frame: FaceTrackingFrame, sharpness: Double, imageURL: URL) {
        guard captureState == .running else {
            return
        }

        let quality = evaluator.score(frame: frame, targetSlot: currentSlot, sharpness: sharpness)
        observedFrameCount += 1
        observedFrameCountBySlot[currentSlot, default: 0] += 1
        latestQuality = quality
        qualityMessage = message(for: quality)

        let candidate = CaptureManifest.CapturedFrame(
            slot: currentSlot,
            localURL: imageURL,
            quality: quality,
            pose: frame.pose,
            capturedAt: Date()
        )
        retainFallbackCandidate(candidate)

        let completionReason = completionReason(
            quality,
            for: currentSlot,
            slotFrameCount: observedFrameCountBySlot[currentSlot, default: 0]
        )
        guard let completionReason else {
            return
        }

        complete(
            slot: currentSlot,
            with: completionReason == .detectedExpression ? candidate : (fallbackCandidates[currentSlot] ?? candidate)
        )
    }

    func failCapture(_ message: String) {
        errorMessage = message
        captureState = .failed
        qualityMessage = message
    }

    func resetAfterFailure() {
        currentSlot = .neutralFront
        completedSlots = []
        selectedFrames = [:]
        canContinue = false
        errorMessage = nil
        qualityMessage = "Center your face in the oval."
        observedFrameCount = 0
        latestQuality = nil
        observedFrameCountBySlot = [:]
        fallbackCandidates = [:]
        captureState = .idle
    }

    func makeManifest(device: CaptureManifest.Device) -> CaptureManifest {
        CaptureManifest(
            schemaVersion: 1,
            createdAt: Date(),
            device: device,
            captureSlots: CaptureSlot.allCases.compactMap { selectedFrames[$0] }
        )
    }

    private func advanceSlot() {
        guard let next = CaptureSlot.allCases.first(where: { !completedSlots.contains($0) }) else {
            return
        }

        currentSlot = next
    }

    private func message(for quality: FaceQualityScore) -> String {
        if quality.lighting < 0.5 {
            return "Face detected. Move to softer, brighter light."
        }
        if currentSlot == .blink && quality.expressionMatch < blinkExpressionThreshold {
            return "Face detected. Blink once."
        }
        if currentSlot == .mouthOpen && quality.expressionMatch < mouthExpressionThreshold {
            return "Face detected. Open your mouth."
        }
        if currentSlot == .smile && quality.expressionMatch < smileExpressionThreshold {
            return "Face detected. Smile."
        }
        if quality.sharpness < 0.5 {
            return "Face detected. Hold still for a clearer frame."
        }
        if quality.poseMatch < 0.5 {
            return "Face detected. \(currentSlot.prompt)."
        }
        if quality.total < acceptanceThreshold {
            return "Face detected. Hold that pose."
        }
        return "Captured. Keep going."
    }

    private func completionReason(
        _ quality: FaceQualityScore,
        for slot: CaptureSlot,
        slotFrameCount: Int
    ) -> SlotCompletionReason? {
        switch slot {
        case .blink:
            let baseQuality = (quality.lighting + quality.sharpness + quality.poseMatch) / 3
            let detectedBlink = quality.expressionMatch >= blinkExpressionThreshold
                && quality.lighting >= 0.2
                && quality.poseMatch >= 0.2
            if detectedBlink {
                return .detectedExpression
            }

            let stableFallback = slotFrameCount >= blinkFallbackFrameCount
                && baseQuality >= 0.42
            return stableFallback ? .stableFallback : nil
        case .mouthOpen:
            return expressionCompletionReason(
                quality,
                expressionThreshold: mouthExpressionThreshold,
                slotFrameCount: slotFrameCount
            )
        case .smile:
            return expressionCompletionReason(
                quality,
                expressionThreshold: smileExpressionThreshold,
                slotFrameCount: slotFrameCount
            )
        case .neutralFront, .turnLeft, .turnRight, .lookUp, .lookDown:
            return quality.total >= acceptanceThreshold ? .standard : nil
        }
    }

    private func expressionCompletionReason(
        _ quality: FaceQualityScore,
        expressionThreshold: Double,
        slotFrameCount: Int
    ) -> SlotCompletionReason? {
        let detectedExpression = quality.expressionMatch >= expressionThreshold
            && quality.lighting >= 0.2
            && quality.poseMatch >= 0.2
        if detectedExpression {
            return .detectedExpression
        }

        let baseQuality = (quality.lighting + quality.sharpness + quality.poseMatch) / 3
        let stableFallback = slotFrameCount >= expressionFallbackFrameCount
            && baseQuality >= 0.42
        return stableFallback ? .stableFallback : nil
    }

    private func retainFallbackCandidate(_ candidate: CaptureManifest.CapturedFrame) {
        guard let existing = fallbackCandidates[candidate.slot] else {
            fallbackCandidates[candidate.slot] = candidate
            return
        }

        if candidate.quality.total > existing.quality.total {
            fallbackCandidates[candidate.slot] = candidate
        }
    }

    private func complete(slot: CaptureSlot, with candidate: CaptureManifest.CapturedFrame) {
        selectedFrames = selector.bestFrames(from: Array(selectedFrames.values) + [candidate])
        completedSlots.insert(slot)
        canContinue = selector.isComplete(selectedFrames)
        advanceSlot()
    }
}

private enum SlotCompletionReason {
    case standard
    case detectedExpression
    case stableFallback
}

enum CaptureState: Equatable {
    case idle
    case requestingPermission
    case running
    case unsupported
    case permissionDenied
    case failed
}
