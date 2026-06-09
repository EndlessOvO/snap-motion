import Foundation

struct AvatarJobClient {
    let apiClient: APIClient

    func createJob(deviceID: String, manifest: CaptureManifest) async throws -> AvatarJobCreationResponse {
        let payload = CreateAvatarJobRequest(
            deviceID: deviceID,
            client: .init(platform: "ios", appVersion: manifest.device.appVersion, osVersion: manifest.device.osVersion),
            manifest: manifest
        )
        let request = try apiClient.request(path: "/v1/avatar-jobs", method: "POST", body: payload)
        return try await apiClient.send(request, as: AvatarJobCreationResponse.self)
    }

    func completeUploads(jobID: String) async throws {
        let request = try apiClient.request(path: "/v1/avatar-jobs/\(jobID)/uploads/complete", method: "POST")
        try await apiClient.send(request)
    }

    func fetchJob(jobID: String) async throws -> AvatarJob {
        let request = try apiClient.request(path: "/v1/avatar-jobs/\(jobID)")
        return try await apiClient.send(request, as: AvatarJob.self)
    }

    func fetchAvatar(avatarID: String) async throws -> AvatarRecipe {
        let request = try apiClient.request(path: "/v1/avatars/\(avatarID)")
        return try await apiClient.send(request, as: AvatarRecipe.self)
    }
}

private struct CreateAvatarJobRequest: Encodable {
    let deviceID: String
    let client: Client
    let manifest: CaptureManifest

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case client
        case manifest
    }

    struct Client: Encodable {
        let platform: String
        let appVersion: String
        let osVersion: String

        enum CodingKeys: String, CodingKey {
            case platform
            case appVersion = "app_version"
            case osVersion = "os_version"
        }
    }
}
