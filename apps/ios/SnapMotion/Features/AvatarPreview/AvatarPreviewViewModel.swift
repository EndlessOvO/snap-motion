import Foundation

@MainActor
final class AvatarPreviewViewModel: ObservableObject {
    @Published private(set) var recipe: AvatarRecipe = .fixture
    @Published private(set) var renderer = SceneKitAvatarRenderer()
    @Published var blink: Double = 0
    @Published var jawOpen: Double = 0
    @Published var smile: Double = 0

    init(recipe: AvatarRecipe = .fixture) {
        self.recipe = recipe
    }

    func load() async {
        do {
            try await renderer.load(recipe: recipe)
            applyManualExpression()
        } catch {
            // The template asset is expected to be added after the Xcode project is created.
        }
    }

    func applyManualExpression() {
        renderer.apply(
            expression: AvatarExpressionFrame(
                morphWeights: [
                    "blink_L": blink,
                    "blink_R": blink,
                    "jaw_open": jawOpen,
                    "smile_L": smile,
                    "smile_R": smile
                ],
                pose: .neutral
            )
        )
    }
}
