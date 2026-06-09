import SwiftUI

struct AvatarPreviewView: View {
    @StateObject var viewModel: AvatarPreviewViewModel

    var body: some View {
        VStack(spacing: 18) {
            AvatarSceneView(scene: viewModel.renderer.scene)
                .frame(maxWidth: .infinity)
                .aspectRatio(0.78, contentMode: .fit)
                .background(SnapColors.sky.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
        }
        .background(SnapColors.background.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            slider(title: "Blink", value: $viewModel.blink)
            slider(title: "Mouth", value: $viewModel.jawOpen)
            slider(title: "Smile", value: $viewModel.smile)
        }
        .onChange(of: viewModel.blink) { _, _ in viewModel.applyManualExpression() }
        .onChange(of: viewModel.jawOpen) { _, _ in viewModel.applyManualExpression() }
        .onChange(of: viewModel.smile) { _, _ in viewModel.applyManualExpression() }
    }

    private func slider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SnapTypography.caption)
                .foregroundStyle(SnapColors.ink.opacity(0.75))
            Slider(value: value, in: 0...1)
                .tint(SnapColors.coral)
        }
    }
}
