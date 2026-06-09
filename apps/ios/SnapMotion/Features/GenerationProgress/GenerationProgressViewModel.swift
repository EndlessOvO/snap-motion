import Foundation

@MainActor
final class GenerationProgressViewModel: ObservableObject {
    @Published private(set) var statusText: String = "Preparing upload"
    @Published private(set) var progress: Double = 0.15
    @Published private(set) var recipe: AvatarRecipe?
    @Published private(set) var errorMessage: String?

    private let jobClient: AvatarJobClient

    init(jobClient: AvatarJobClient) {
        self.jobClient = jobClient
    }

    func useFixture() {
        statusText = "Avatar ready"
        progress = 1
        recipe = .fixture
    }

    func poll(jobID: String) async {
        do {
            while true {
                let job = try await jobClient.fetchJob(jobID: jobID)
                updateProgress(for: job.status)

                if job.status == .succeeded, let avatarID = job.avatarID {
                    recipe = try await jobClient.fetchAvatar(avatarID: avatarID)
                    progress = 1
                    statusText = "Avatar ready"
                    return
                }

                if job.status.isTerminal {
                    errorMessage = job.errorMessage ?? "Avatar generation did not complete."
                    return
                }

                try await Task.sleep(for: .seconds(1.5))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateProgress(for status: AvatarJob.Status) {
        switch status {
        case .waitingForUpload:
            statusText = "Waiting for upload"
            progress = 0.2
        case .queued:
            statusText = "Waiting in line"
            progress = 0.35
        case .processing:
            statusText = "Designing your avatar"
            progress = 0.72
        case .succeeded:
            statusText = "Avatar ready"
            progress = 1
        case .failed:
            statusText = "Generation failed"
        case .expired:
            statusText = "Generation expired"
        }
    }
}
