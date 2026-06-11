import Foundation
import SwiftUI

struct AppRouter: View {
    private let launchConfiguration = UITestLaunchConfiguration()
    @State private var route: Route
    @AppStorage("snap_motion_age_confirmed") private var ageConfirmed = false
    private let avatarJobClient = AvatarJobClient(apiClient: .generation())
    private let uploadClient = UploadClient.generation
    private let deviceIdentityStore = DeviceIdentityStore()

    init() {
        let configuration = UITestLaunchConfiguration()
        switch configuration.scenario {
        case .previewFixture:
            _route = State(initialValue: .avatarPreview(.fixture))
        case .generationFailure:
            _route = State(initialValue: .generationProgress(.uiTestFixture))
        case .normal, .cameraDenied, .unsupportedFaceTracking:
            _route = State(initialValue: .enrollment)
        }
    }

    var body: some View {
        Group {
            if shouldShowAgeGate {
                AgeGateView {
                    ageConfirmed = true
                }
            } else {
                NavigationStack {
                    content
                        .navigationTitle(route.title)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .enrollment:
            FaceEnrollmentView(
                viewModel: FaceEnrollmentViewModel(
                    permissionService: permissionService,
                    forceFaceTrackingSupport: forcedFaceTrackingSupport
                ),
                onEnrollmentComplete: { manifest in route = .generationProgress(manifest) },
                onPreviewDemo: { route = .avatarPreview(.fixture) }
            )
        case .generationProgress(let manifest):
            GenerationProgressView(
                viewModel: GenerationProgressViewModel(
                    manifest: manifest,
                    deviceID: deviceIdentityStore.deviceID(),
                    jobClient: launchConfiguration.scenario == .generationFailure ? .failingFixture : avatarJobClient,
                    uploadClient: uploadClient,
                    avatarCache: AvatarCache()
                ),
                onCompleted: { recipe in route = .avatarPreview(recipe) }
            )
        case .avatarPreview(let recipe):
            AvatarPreviewView(viewModel: AvatarPreviewViewModel(recipe: recipe))
        }
    }

    private var permissionService: CameraPermissionService {
        switch launchConfiguration.scenario {
        case .cameraDenied:
            return .fixed(status: .denied)
        case .normal, .unsupportedFaceTracking, .previewFixture, .generationFailure:
            return CameraPermissionService()
        }
    }

    private var forcedFaceTrackingSupport: Bool? {
        switch launchConfiguration.scenario {
        case .cameraDenied:
            return true
        case .unsupportedFaceTracking:
            return false
        case .normal, .previewFixture, .generationFailure:
            return nil
        }
    }

    private var shouldShowAgeGate: Bool {
        !ageConfirmed && launchConfiguration.scenario != .previewFixture
    }
}

private enum Route {
    case enrollment
    case generationProgress(CaptureManifest)
    case avatarPreview(AvatarRecipe)

    var title: String {
        switch self {
        case .enrollment:
            return "Face Enrollment"
        case .generationProgress:
            return "Generating Avatar"
        case .avatarPreview:
            return "Avatar Preview"
        }
    }
}

private extension CaptureManifest {
    static let uiTestFixture = CaptureManifest(
        schemaVersion: 1,
        createdAt: Date(timeIntervalSince1970: 0),
        device: .init(model: "UITest", osVersion: "17.0", appVersion: "1.0.0"),
        captureSlots: CaptureSlot.allCases.map { slot in
            CapturedFrame(
                slot: slot,
                localURL: URL(fileURLWithPath: "/tmp/\(slot.rawValue).jpg"),
                quality: FaceQualityScore(lighting: 1, sharpness: 1, poseMatch: 1, expressionMatch: 1),
                pose: .neutral,
                capturedAt: Date(timeIntervalSince1970: 0)
            )
        }
    )
}
