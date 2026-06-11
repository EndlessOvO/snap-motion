import SwiftUI

struct FaceEnrollmentView: View {
    @StateObject var viewModel: FaceEnrollmentViewModel

    let onEnrollmentComplete: (CaptureManifest) -> Void
    let onPreviewDemo: () -> Void

    var body: some View {
        ZStack {
            SnapColors.background.ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    if viewModel.captureState == .running {
                        ARFaceCameraView(
                            currentSlot: viewModel.currentSlot,
                            onFrame: { frame, sharpness, imageURL in
                                viewModel.ingest(frame: frame, sharpness: sharpness, imageURL: imageURL)
                            },
                            onError: { message in
                                viewModel.failCapture(message)
                            }
                        )
                        .background(SnapColors.sky.opacity(0.12))
                    } else {
                        Rectangle()
                            .fill(SnapColors.sky.opacity(0.12))
                    }
                }
                .aspectRatio(0.72, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    EnrollmentGuideOverlay(progress: viewModel.progress, prompt: viewModel.prompt)
                }
                .overlay {
                    if viewModel.captureState != .running {
                        statusOverlay
                    }
                }
                .padding(.horizontal, 28)

                captureProgressStrip
                    .padding(.horizontal, 28)

                VStack(spacing: 8) {
                    Text(viewModel.qualityMessage)
                        .font(SnapTypography.body)
                        .foregroundStyle(SnapColors.ink.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 44)

                    if let latestQuality = viewModel.latestQuality {
                        Text(qualitySummary(latestQuality))
                            .font(SnapTypography.caption)
                            .foregroundStyle(SnapColors.ink.opacity(0.58))
                            .monospacedDigit()
                    } else if viewModel.captureState == .running {
                        Text("Looking for a face")
                            .font(SnapTypography.caption)
                            .foregroundStyle(SnapColors.ink.opacity(0.58))
                    }
                }
                .padding(.horizontal, 28)

                HStack(spacing: 12) {
                    Button("Demo Avatar") {
                        onPreviewDemo()
                    }
                    .buttonStyle(.bordered)
                    .tint(SnapColors.sky)

                    Button("Use Enrollment") {
                        let manifest = viewModel.makeManifest(device: viewModel.device)
                        onEnrollmentComplete(manifest)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SnapColors.coral)
                    .disabled(!viewModel.canContinue)
                }
                .padding(.horizontal, 28)

                if viewModel.canContinue {
                    Text("All capture poses are ready.")
                        .font(SnapTypography.caption)
                        .foregroundStyle(SnapColors.mint)
                } else {
                    Text("\(viewModel.completedSlots.count) of \(CaptureSlot.allCases.count) poses captured")
                        .font(SnapTypography.caption)
                        .foregroundStyle(SnapColors.ink.opacity(0.58))
                }

                Spacer(minLength: 0)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(SnapTypography.caption)
                        .foregroundStyle(SnapColors.coral)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                if viewModel.captureState == .failed || viewModel.captureState == .permissionDenied {
                    SnapPrimaryButton(title: "Retry Capture") {
                        viewModel.resetAfterFailure()
                        Task {
                            await startCaptureIfPossible()
                        }
                    }
                    .padding(.horizontal, 28)
                }
            }
        }
        .task {
            await startCaptureIfPossible()
        }
    }

    private var captureProgressStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CaptureSlot.allCases, id: \.self) { slot in
                    Text(slot.shortLabel)
                        .font(SnapTypography.caption)
                        .foregroundStyle(labelColor(for: slot))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(labelBackground(for: slot))
                        )
                }
            }
        }
        .accessibilityIdentifier("Capture Progress")
    }

    private var statusOverlay: some View {
        VStack(spacing: 10) {
            ProgressView()
                .opacity(viewModel.captureState == .requestingPermission ? 1 : 0)

            Text(statusText)
                .font(SnapTypography.body)
                .foregroundStyle(SnapColors.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
    }

    private var statusText: String {
        switch viewModel.captureState {
        case .idle:
            return "Preparing camera"
        case .requestingPermission:
            return "Requesting camera access"
        case .running:
            return ""
        case .unsupported:
            return "TrueDepth face tracking is not available on this device."
        case .permissionDenied:
            return "Camera access is disabled."
        case .failed:
            return "Capture stopped."
        }
    }

    private func startCaptureIfPossible() async {
        _ = await viewModel.prepareCapture(isFaceTrackingSupported: ARFaceTrackingSession.isFaceTrackingSupported)
    }

    private func labelColor(for slot: CaptureSlot) -> Color {
        if viewModel.completedSlots.contains(slot) || viewModel.currentSlot == slot {
            return .white
        }

        return SnapColors.ink.opacity(0.62)
    }

    private func labelBackground(for slot: CaptureSlot) -> Color {
        if viewModel.completedSlots.contains(slot) {
            return SnapColors.mint
        }

        if viewModel.currentSlot == slot {
            return SnapColors.sky
        }

        return SnapColors.ink.opacity(0.08)
    }

    private func qualitySummary(_ quality: FaceQualityScore) -> String {
        let total = Int(quality.total * 100)
        let light = Int(quality.lighting * 100)
        let sharp = Int(quality.sharpness * 100)
        let pose = Int(quality.poseMatch * 100)
        let expression = Int(quality.expressionMatch * 100)
        return "Score \(total)%  Light \(light)%  Sharp \(sharp)%  Pose \(pose)%  Expr \(expression)%"
    }
}

#Preview {
    FaceEnrollmentView(
        viewModel: FaceEnrollmentViewModel(),
        onEnrollmentComplete: { _ in },
        onPreviewDemo: {}
    )
}

private extension CaptureSlot {
    var shortLabel: String {
        switch self {
        case .neutralFront:
            return "Front"
        case .turnLeft:
            return "Left"
        case .turnRight:
            return "Right"
        case .lookUp:
            return "Up"
        case .lookDown:
            return "Down"
        case .blink:
            return "Blink"
        case .mouthOpen:
            return "Mouth"
        case .smile:
            return "Smile"
        }
    }
}
