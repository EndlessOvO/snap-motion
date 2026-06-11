import Foundation

struct UploadClient {
    var urlSession: URLSession = .shared

    static let generation = UploadClient(urlSession: {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 180
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }())

    func upload(fileURL: URL, to slot: AvatarUploadSlot) async throws {
        var request = URLRequest(url: slot.url)
        request.httpMethod = slot.method
        request.setValue(slot.contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await urlSession.upload(for: request, fromFile: fileURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw UploadClientError.uploadFailed
        }
    }
}

enum UploadClientError: Error, LocalizedError {
    case uploadFailed

    var errorDescription: String? {
        "Upload failed."
    }
}
