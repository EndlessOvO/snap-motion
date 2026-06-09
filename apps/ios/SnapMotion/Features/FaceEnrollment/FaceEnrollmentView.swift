import SwiftUI

struct FaceEnrollmentView: View {
    @StateObject var viewModel: FaceEnrollmentViewModel

    let onEnrollmentComplete: (CaptureManifest) -> Void

    var body: some View {
        ZStack {
            SnapColors.background.ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SnapColors.sky.opacity(0.12))
                        .aspectRatio(0.72, contentMode: .fit)
                        .overlay {
                            EnrollmentGuideOverlay(progress: viewModel.progress, prompt: viewModel.prompt)
                        }
                }
                .padding(.horizontal, 28)

                Text(viewModel.qualityMessage)
                    .font(SnapTypography.body)
                    .foregroundStyle(SnapColors.ink.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 28)

                SnapPrimaryButton(title: "Use Enrollment") {
                    let manifest = viewModel.makeManifest(
                        device: .init(model: "iPhone", osVersion: "17.0", appVersion: "1.0.0")
                    )
                    onEnrollmentComplete(manifest)
                }
                .disabled(!viewModel.canContinue)
                .padding(.horizontal, 28)
            }
        }
    }
}

#Preview {
    FaceEnrollmentView(viewModel: FaceEnrollmentViewModel(), onEnrollmentComplete: { _ in })
}
