import Foundation
import AVFoundation

@MainActor
final class AvatarPreviewViewModel: ObservableObject {
    @Published private(set) var recipe: AvatarRecipe = .fixture
    @Published private(set) var renderer = SceneKitAvatarRenderer()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var liveModeStatus: LiveModeStatus = .manual
    @Published var blink: Double = 0
    @Published var jawOpen: Double = 0
    @Published var smile: Double = 0

    private let expressionMapper: AvatarExpressionMapper
    private let permissionService: CameraPermissionService

    init(
        recipe: AvatarRecipe = .fixture,
        expressionMapper: AvatarExpressionMapper = AvatarExpressionMapper(),
        permissionService: CameraPermissionService = CameraPermissionService()
    ) {
        self.recipe = recipe
        self.expressionMapper = expressionMapper
        self.permissionService = permissionService
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            try await renderer.load(recipe: recipe)
            applyManualExpression()
        } catch {
            errorMessage = error.localizedDescription
        }

        if let loadNotice = renderer.loadNotice {
            errorMessage = loadNotice
        }

        isLoading = false
    }

    func applyManualExpression() {
        guard liveModeStatus != .live else {
            return
        }

        renderer.apply(
            expression: AvatarExpressionFrame(
                morphWeights: [
                    "blink_L": blink,
                    "blink_R": blink,
                    "jaw_open": jawOpen,
                    "smile_L": smile,
                    "smile_R": smile
                ],
                pose: .neutral
            )
        )
    }

    func retryLoad() async {
        await load()
    }

    func startLiveMode(isFaceTrackingSupported: Bool) async -> Bool {
        guard isFaceTrackingSupported else {
            liveModeStatus = .unsupported
            errorMessage = "Live preview requires a TrueDepth front camera."
            return false
        }

        switch permissionService.authorizationStatus() {
        case .authorized:
            liveModeStatus = .live
            errorMessage = nil
            return true
        case .notDetermined:
            liveModeStatus = .requestingPermission
            let granted = await permissionService.requestAccess()
            liveModeStatus = granted ? .live : .permissionDenied
            errorMessage = granted ? nil : "Camera access is required for live avatar preview."
            return granted
        case .denied, .restricted:
            liveModeStatus = .permissionDenied
            errorMessage = "Camera access is required for live avatar preview."
            return false
        @unknown default:
            liveModeStatus = .failed
            errorMessage = "Camera permission is unavailable."
            return false
        }
    }

    func stopLiveMode() {
        liveModeStatus = .manual
        applyManualExpression()
    }

    func applyLiveFrame(_ frame: FaceTrackingFrame) {
        guard liveModeStatus == .live else {
            return
        }

        renderer.apply(expression: expressionMapper.expression(from: frame, recipe: recipe))
    }
}

enum LiveModeStatus: Equatable {
    case manual
    case requestingPermission
    case live
    case unsupported
    case permissionDenied
    case failed
}
