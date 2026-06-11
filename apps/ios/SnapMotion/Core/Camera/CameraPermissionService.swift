import AVFoundation

struct CameraPermissionService {
    var authorizationStatusProvider: () -> AVAuthorizationStatus = {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    var requestAccessProvider: () async -> Bool = {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    func authorizationStatus() -> AVAuthorizationStatus {
        authorizationStatusProvider()
    }

    func requestAccess() async -> Bool {
        await requestAccessProvider()
    }

    static func fixed(status: AVAuthorizationStatus, requestResult: Bool = false) -> CameraPermissionService {
        CameraPermissionService(
            authorizationStatusProvider: { status },
            requestAccessProvider: { requestResult }
        )
    }
}
