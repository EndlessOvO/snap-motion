import Foundation

struct AvatarAssetCache {
    private let fileManager: FileManager
    private let urlSession: URLSession
    private let maxAge: TimeInterval

    init(
        fileManager: FileManager = .default,
        urlSession: URLSession = .shared,
        maxAge: TimeInterval = 7 * 24 * 60 * 60
    ) {
        self.fileManager = fileManager
        self.urlSession = urlSession
        self.maxAge = maxAge
    }

    func cachedURL(for remoteURL: URL) async throws -> URL {
        let destination = cacheURL(for: remoteURL)
        if try isFreshFile(at: destination) {
            return destination
        }

        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let (temporaryURL, response) = try await urlSession.download(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw AvatarAssetCacheError.downloadFailed(remoteURL)
        }

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    func prefetch(recipe: AvatarRecipe) async -> [URL: URL] {
        var cachedURLs: [URL: URL] = [:]

        for remoteURL in recipe.materials.allTextureURLs {
            guard remoteURL.scheme == "http" || remoteURL.scheme == "https" else {
                continue
            }
            do {
                cachedURLs[remoteURL] = try await cachedURL(for: remoteURL)
            } catch {
                continue
            }
        }

        return cachedURLs
    }

    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "SnapMotion")
            .appending(path: "Assets")
    }

    private func cacheURL(for remoteURL: URL) -> URL {
        let extensionName = remoteURL.pathExtension.isEmpty ? "asset" : remoteURL.pathExtension
        return cacheDirectory.appending(path: "\(remoteURL.absoluteString.stableCacheKey).\(extensionName)")
    }

    private func isFreshFile(at url: URL) throws -> Bool {
        guard fileManager.fileExists(atPath: url.path) else {
            return false
        }

        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let modifiedAt = attributes[.modificationDate] as? Date else {
            return false
        }

        return Date().timeIntervalSince(modifiedAt) <= maxAge
    }
}

enum AvatarAssetCacheError: Error, LocalizedError {
    case downloadFailed(URL)

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let url):
            return "Could not cache avatar asset at \(url.absoluteString)."
        }
    }
}

private extension AvatarRecipe.Materials {
    var allTextureURLs: [URL] {
        [skinTextureURL, hairTextureURL] + extraTextureURLs
    }
}

private extension String {
    var stableCacheKey: String {
        let scalars = unicodeScalars.map { UInt64($0.value) }
        let hash = scalars.reduce(UInt64(14_695_981_039_346_656_037)) { result, value in
            (result ^ value) &* 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}
