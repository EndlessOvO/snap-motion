import Foundation

struct AvatarJob: Codable, Equatable, Identifiable {
    let id: String
    let status: Status
    let avatarID: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id = "job_id"
        case status
        case avatarID = "avatar_id"
        case errorMessage = "error_message"
    }
}

extension AvatarJob {
    enum Status: String, Codable {
        case waitingForUpload = "waiting_for_upload"
        case queued
        case processing
        case succeeded
        case failed
        case expired

        var isTerminal: Bool {
            switch self {
            case .succeeded, .failed, .expired:
                return true
            case .waitingForUpload, .queued, .processing:
                return false
            }
        }
    }
}

struct AvatarUploadSlot: Codable, Equatable, Identifiable {
    let slot: CaptureSlot
    let url: URL
    let method: String
    let contentType: String

    var id: CaptureSlot { slot }

    enum CodingKeys: String, CodingKey {
        case slot
        case url
        case method
        case contentType = "content_type"
    }
}

struct AvatarJobCreationResponse: Codable, Equatable {
    let jobID: String
    let status: AvatarJob.Status
    let uploadURLs: [AvatarUploadSlot]

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
        case status
        case uploadURLs = "upload_urls"
    }
}
