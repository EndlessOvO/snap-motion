import Foundation

struct AvatarJobClient {
    let apiClient: APIClient
    var createJobHandler: ((String, CaptureManifest) async throws -> AvatarJobCreationResponse)?
    var completeUploadsHandler: ((String) async throws -> Void)?
    var fetchJobHandler: ((String) async throws -> AvatarJob)?
    var fetchAvatarHandler: ((String) async throws -> AvatarRecipe)?

    func createJob(deviceID: String, manifest: CaptureManifest) async throws -> AvatarJobCreationResponse {
        if let createJobHandler {
            return try await createJobHandler(deviceID, manifest)
        }

        let payload = CreateAvatarJobRequest(
            deviceID: deviceID,
            client: .init(platform: "ios", appVersion: manifest.device.appVersion, osVersion: manifest.device.osVersion),
            manifest: manifest
        )
        let request = try apiClient.request(path: "/v1/avatar-jobs", method: "POST", body: payload)
        return try await apiClient.send(request, as: AvatarJobCreationResponse.self)
    }

    func completeUploads(jobID: String) async throws {
        if let completeUploadsHandler {
            return try await completeUploadsHandler(jobID)
        }

        let request = try apiClient.request(path: "/v1/avatar-jobs/\(jobID)/uploads/complete", method: "POST")
        try await apiClient.send(request)
    }

    func fetchJob(jobID: String) async throws -> AvatarJob {
        if let fetchJobHandler {
            return try await fetchJobHandler(jobID)
        }

        let request = try apiClient.request(path: "/v1/avatar-jobs/\(jobID)")
        return try await apiClient.send(request, as: AvatarJob.self)
    }

    func fetchAvatar(avatarID: String) async throws -> AvatarRecipe {
        if let fetchAvatarHandler {
            return try await fetchAvatarHandler(avatarID)
        }

        let request = try apiClient.request(path: "/v1/avatars/\(avatarID)")
        return try await apiClient.send(request, as: AvatarRecipe.self)
    }
}

extension AvatarJobClient {
    static let failingFixture = AvatarJobClient(
        apiClient: APIClient(),
        createJobHandler: { _, _ in
            AvatarJobCreationResponse(jobID: "job_ui_failure", status: .waitingForUpload, uploadURLs: [])
        },
        completeUploadsHandler: { _ in },
        fetchJobHandler: { _ in
            AvatarJob(
                id: "job_ui_failure",
                status: .failed,
                avatarID: nil,
                errorMessage: "UI test generation failure."
            )
        },
        fetchAvatarHandler: { _ in .fixture }
    )
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
