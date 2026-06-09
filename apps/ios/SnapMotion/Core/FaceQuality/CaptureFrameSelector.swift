import Foundation

struct CaptureFrameSelector {
    func bestFrames(from candidates: [CaptureManifest.CapturedFrame]) -> [CaptureSlot: CaptureManifest.CapturedFrame] {
        candidates.reduce(into: [:]) { bestBySlot, candidate in
            guard let existing = bestBySlot[candidate.slot] else {
                bestBySlot[candidate.slot] = candidate
                return
            }

            if candidate.quality > existing.quality {
                bestBySlot[candidate.slot] = candidate
            }
        }
    }

    func isComplete(_ selectedFrames: [CaptureSlot: CaptureManifest.CapturedFrame]) -> Bool {
        CaptureSlot.allCases.allSatisfy { selectedFrames[$0] != nil }
    }
}
