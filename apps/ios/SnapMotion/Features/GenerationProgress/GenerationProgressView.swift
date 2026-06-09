import SwiftUI

struct GenerationProgressView: View {
    @StateObject var viewModel: GenerationProgressViewModel

    let onCompleted: (AvatarRecipe) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(SnapColors.mint)
                .padding(.horizontal, 36)

            Text(viewModel.statusText)
                .font(SnapTypography.headline)
                .foregroundStyle(SnapColors.ink)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(SnapTypography.body)
                    .foregroundStyle(SnapColors.coral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer()

            SnapPrimaryButton(title: "Preview Fixture") {
                viewModel.useFixture()
                if let recipe = viewModel.recipe {
                    onCompleted(recipe)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .background(SnapColors.background.ignoresSafeArea())
    }
}
