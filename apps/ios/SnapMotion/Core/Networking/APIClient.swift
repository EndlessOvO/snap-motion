import Foundation

struct APIClient {
    var baseURL: URL
    var urlSession: URLSession
    var jsonDecoder: JSONDecoder
    var jsonEncoder: JSONEncoder

    init(
        baseURL: URL = URL(string: "https://api.snap-motion.local")!,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder
    }

    func send<Response: Decodable>(_ request: URLRequest, as type: Response.Type) async throws -> Response {
        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response, data: data)
        return try jsonDecoder.decode(Response.self, from: data)
    }

    func send(_ request: URLRequest) async throws {
        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response, data: data)
    }

    func request(path: String, method: String = "GET", body: Encodable? = nil) throws -> URLRequest {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try jsonEncoder.encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode, data)
        }
    }
}

enum APIClientError: Error, LocalizedError {
    case invalidResponse
    case httpStatus(Int, Data)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .httpStatus(let statusCode, _):
            return "Server returned HTTP \(statusCode)."
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
