import Foundation
import XCTest
@testable import SnapMotion

final class AvatarRecipeTests: XCTestCase {
    func testFixtureRoundTripsThroughJSON() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(AvatarRecipe.fixture)
        let decoded = try decoder.decode(AvatarRecipe.self, from: data)

        XCTAssertEqual(decoded, .fixture)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.rig.templateID, "cute_avatar_v1")
    }
}
