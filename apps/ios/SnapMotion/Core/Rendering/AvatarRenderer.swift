import Foundation

protocol AvatarRenderer: AnyObject {
    func load(recipe: AvatarRecipe) async throws
    func apply(expression: AvatarExpressionFrame)
}

struct AvatarExpressionFrame: Equatable {
    let morphWeights: [String: Double]
    let pose: FacePose
}
