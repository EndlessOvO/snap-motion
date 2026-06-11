import Foundation
import XCTest
@testable import SnapMotion

@MainActor
final class GenerationProgressViewModelTests: XCTestCase {
    func testFallsBackToLocalRecipeWhenCreateJobTimesOut() async {
        var didTryCreateJob = false
        let viewModel = GenerationProgressViewModel(
            manifest: .singleFrameFixture,
            deviceID: "device-timeout",
            jobClient: AvatarJobClient(
                apiClient: APIClient(),
                createJobHandler: { _, _ in
                    didTryCreateJob = true
                    throw URLError(.timedOut)
                }
            ),
            uploadClient: UploadClient(),
            avatarCache: AvatarCache(),
            sleep: { _ in }
        )

        await viewModel.start()

        XCTAssertTrue(didTryCreateJob)
        XCTAssertEqual(viewModel.statusText, "Avatar ready")
        XCTAssertEqual(viewModel.recipe?.rig.templateID, "procedural_cute_avatar_v1")
        XCTAssertTrue(viewModel.recipe?.avatarID.hasPrefix("avatar_local_") == true)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testContinuesPollingWhenCompleteUploadsTimesOut() async {
        var didFetchJob = false
        let viewModel = GenerationProgressViewModel(
            manifest: .singleFrameFixture,
            jobClient: AvatarJobClient(
                apiClient: APIClient(),
                createJobHandler: { _, _ in
                    AvatarJobCreationResponse(
                        jobID: "job_timeout",
                        status: .waitingForUpload,
                        uploadURLs: []
                    )
                },
                completeUploadsHandler: { _ in
                    throw URLError(.timedOut)
                },
                fetchJobHandler: { _ in
                    didFetchJob = true
                    return AvatarJob(
                        id: "job_timeout",
                        status: .succeeded,
                        avatarID: "avatar_timeout",
                        errorMessage: nil
                    )
                },
                fetchAvatarHandler: { _ in .fixture }
            ),
            uploadClient: UploadClient(),
            avatarCache: AvatarCache(),
            sleep: { _ in }
        )

        await viewModel.start()

        XCTAssertTrue(didFetchJob)
        XCTAssertEqual(viewModel.statusText, "Avatar ready")
        XCTAssertEqual(viewModel.recipe?.avatarID, AvatarRecipe.fixture.avatarID)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFallsBackToLocalRecipeAfterRepeatedPollingNetworkFailures() async {
        var fetchAttempts = 0
        let viewModel = GenerationProgressViewModel(
            manifest: .singleFrameFixture,
            deviceID: "device-poll-timeout",
            jobClient: AvatarJobClient(
                apiClient: APIClient(),
                createJobHandler: { _, _ in
                    AvatarJobCreationResponse(
                        jobID: "job_poll_timeout",
                        status: .waitingForUpload,
                        uploadURLs: []
                    )
                },
                completeUploadsHandler: { _ in },
                fetchJobHandler: { _ in
                    fetchAttempts += 1
                    throw URLError(.networkConnectionLost)
                }
            ),
            uploadClient: UploadClient(),
            avatarCache: AvatarCache(),
            sleep: { _ in }
        )

        await viewModel.start()

        XCTAssertEqual(fetchAttempts, 6)
        XCTAssertEqual(viewModel.statusText, "Avatar ready")
        XCTAssertEqual(viewModel.recipe?.rig.templateID, "procedural_cute_avatar_v1")
        XCTAssertNil(viewModel.errorMessage)
    }
}

private extension CaptureManifest {
    static let singleFrameFixture = CaptureManifest(
        schemaVersion: 1,
        createdAt: Date(timeIntervalSince1970: 0),
        device: .init(model: "iPhone", osVersion: "17.0", appVersion: "1.0.0"),
        captureSlots: [
            CapturedFrame(
                slot: .neutralFront,
                localURL: URL(fileURLWithPath: "/tmp/neutral.jpg"),
                quality: FaceQualityScore(lighting: 1, sharpness: 1, poseMatch: 1, expressionMatch: 1),
                pose: .neutral,
                capturedAt: Date(timeIntervalSince1970: 0)
            )
        ]
    )
}
