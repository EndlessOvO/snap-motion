import XCTest
@testable import SnapMotion

final class AvatarJobStatusTests: XCTestCase {
    func testTerminalStatuses() {
        XCTAssertFalse(AvatarJob.Status.waitingForUpload.isTerminal)
        XCTAssertFalse(AvatarJob.Status.queued.isTerminal)
        XCTAssertFalse(AvatarJob.Status.processing.isTerminal)
        XCTAssertTrue(AvatarJob.Status.succeeded.isTerminal)
        XCTAssertTrue(AvatarJob.Status.failed.isTerminal)
        XCTAssertTrue(AvatarJob.Status.expired.isTerminal)
    }
}
