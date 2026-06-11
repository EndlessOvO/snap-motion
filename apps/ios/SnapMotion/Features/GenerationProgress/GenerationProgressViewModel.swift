import Foundation

@MainActor
final class GenerationProgressViewModel: ObservableObject {
    @Published private(set) var statusText: String = "Preparing upload"
    @Published private(set) var progress: Double = 0.15
    @Published private(set) var recipe: AvatarRecipe?
    @Published private(set) var errorMessage: String?

    private let manifest: CaptureManifest?
    private let deviceID: String
    private let jobClient: AvatarJobClient
    private let uploadClient: UploadClient
    private let avatarCache: AvatarCache
    private let localRecipeFactory: LocalAvatarRecipeFactory
    private let sleep: (Duration) async throws -> Void
    private var didStart = false
    private var transientNetworkFailures = 0
    private var activeManifest: CaptureManifest?

    init(
        manifest: CaptureManifest? = nil,
        deviceID: String = "preview-device",
        jobClient: AvatarJobClient,
        uploadClient: UploadClient = UploadClient(),
        avatarCache: AvatarCache = AvatarCache(),
        localRecipeFactory: LocalAvatarRecipeFactory = LocalAvatarRecipeFactory(),
        sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.manifest = manifest
        self.deviceID = deviceID
        self.jobClient = jobClient
        self.uploadClient = uploadClient
        self.avatarCache = avatarCache
        self.localRecipeFactory = localRecipeFactory
        self.sleep = sleep
    }

    func start() async {
        guard !didStart else {
            return
        }
        didStart = true

        guard let manifest else {
            useFixture()
            return
        }
        activeManifest = manifest

        do {
            statusText = "Creating generation job"
            progress = 0.18
            let job: AvatarJobCreationResponse
            do {
                job = try await jobClient.createJob(deviceID: deviceID, manifest: manifest)
            } catch {
                guard error.isTransientNetworkError else {
                    throw error
                }
                try finishWithLocalRecipe(from: manifest)
                return
            }

            statusText = "Uploading captures"
            progress = 0.28
            do {
                try await uploadFrames(manifest: manifest, slots: job.uploadURLs)
            } catch {
                guard error.isTransientNetworkError else {
                    throw error
                }
                try finishWithLocalRecipe(from: manifest)
                return
            }

            statusText = "Starting generation"
            progress = 0.34
            do {
                try await jobClient.completeUploads(jobID: job.jobID)
            } catch {
                guard error.isTransientNetworkError else {
                    throw error
                }

                statusText = "Waiting for generation"
                progress = 0.4
            }

            await poll(jobID: job.jobID)
        } catch {
            handleStartupError(error)
        }
    }

    func useFixture() {
        statusText = "Avatar ready"
        progress = 1
        recipe = .fixture
    }

    private func poll(jobID: String) async {
        do {
            while true {
                let job: AvatarJob
                do {
                    job = try await jobClient.fetchJob(jobID: jobID)
                    transientNetworkFailures = 0
                    errorMessage = nil
                } catch {
                    if error.isTransientNetworkError {
                        transientNetworkFailures += 1
                        if transientNetworkFailures >= 6, let activeManifest {
                            try finishWithLocalRecipe(from: activeManifest)
                            return
                        }
                        statusText = "Still waiting for server"
                        progress = max(progress, 0.72)
                        try await sleep(.seconds(min(Double(transientNetworkFailures) * 2, 10)))
                        continue
                    }
                    throw error
                }
                updateProgress(for: job.status)

                if job.status == .succeeded, let avatarID = job.avatarID {
                    let avatarRecipe = try await jobClient.fetchAvatar(avatarID: avatarID)
                    try avatarCache.save(recipe: avatarRecipe)
                    recipe = avatarRecipe
                    progress = 1
                    statusText = "Avatar ready"
                    return
                }

                if job.status.isTerminal {
                    errorMessage = job.errorMessage ?? "Avatar generation did not complete."
                    return
                }

                try await sleep(.seconds(1.5))
            }
        } catch {
            handleStartupError(error)
        }
    }

    private func uploadFrames(manifest: CaptureManifest, slots: [AvatarUploadSlot]) async throws {
        let frameBySlot = Dictionary(uniqueKeysWithValues: manifest.captureSlots.map { ($0.slot, $0) })

        for (index, slot) in slots.enumerated() {
            guard let frame = frameBySlot[slot.slot] else {
                throw GenerationProgressError.missingCaptureFrame(slot.slot)
            }

            try await uploadClient.upload(fileURL: frame.localURL, to: slot)
            progress = 0.28 + (0.05 * (Double(index + 1) / Double(max(slots.count, 1))))
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

    private func handleStartupError(_ error: Error) {
        if error.isTransientNetworkError {
            errorMessage = "The server is taking longer than expected. Please keep this screen open and try again if it does not recover."
            statusText = "Server is still working"
            progress = max(progress, 0.72)
            return
        }

        errorMessage = error.localizedDescription
        statusText = "Generation failed"
    }

    private func finishWithLocalRecipe(from manifest: CaptureManifest) throws {
        statusText = "Building local avatar"
        progress = 0.88
        let localRecipe = localRecipeFactory.makeRecipe(from: manifest, deviceID: deviceID)
        try avatarCache.save(recipe: localRecipe)
        recipe = localRecipe
        progress = 1
        statusText = "Avatar ready"
        errorMessage = nil
    }
}

enum GenerationProgressError: Error, LocalizedError {
    case missingCaptureFrame(CaptureSlot)

    var errorDescription: String? {
        switch self {
        case .missingCaptureFrame(let slot):
            return "Missing capture frame for \(slot.rawValue)."
        }
    }
}

private extension Error {
    var isTransientNetworkError: Bool {
        let nsError = self as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return false
        }

        return [
            NSURLErrorTimedOut,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNotConnectedToInternet
        ].contains(nsError.code)
    }
}
