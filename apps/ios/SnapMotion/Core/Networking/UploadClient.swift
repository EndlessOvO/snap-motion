import Foundation

struct UploadClient {
    var urlSession: URLSession = .shared

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
