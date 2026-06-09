import Foundation

struct AvatarCache {
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func save(recipe: AvatarRecipe) throws {
        let data = try encoder.encode(recipe)
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try data.write(to: recipeURL(for: recipe.avatarID), options: [.atomic])
    }

    func load(avatarID: String) throws -> AvatarRecipe {
        let data = try Data(contentsOf: recipeURL(for: avatarID))
        return try decoder.decode(AvatarRecipe.self, from: data)
    }

    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "SnapMotion")
            .appending(path: "Avatars")
    }

    private func recipeURL(for avatarID: String) -> URL {
        cacheDirectory.appending(path: "\(avatarID).json")
    }
}
