import SwiftUI

struct AppRouter: View {
    @State private var route: Route = .enrollment

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(route.title)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .enrollment:
            FaceEnrollmentView(
                viewModel: FaceEnrollmentViewModel(),
                onEnrollmentComplete: { _ in route = .generationProgress }
            )
        case .generationProgress:
            GenerationProgressView(
                viewModel: GenerationProgressViewModel(jobClient: AvatarJobClient(apiClient: APIClient())),
                onCompleted: { recipe in route = .avatarPreview(recipe) }
            )
        case .avatarPreview(let recipe):
            AvatarPreviewView(viewModel: AvatarPreviewViewModel(recipe: recipe))
        }
    }
}

private enum Route {
    case enrollment
    case generationProgress
    case avatarPreview(AvatarRecipe)

    var title: String {
        switch self {
        case .enrollment:
            return "Face Enrollment"
        case .generationProgress:
            return "Generating Avatar"
        case .avatarPreview:
            return "Avatar Preview"
        }
    }
}
