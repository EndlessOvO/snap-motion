import Foundation

struct LightingEvaluator {
    let targetRange: ClosedRange<Double> = 250...900

    func score(ambientIntensity: Double?) -> Double {
        guard let ambientIntensity else {
            return 0.6
        }

        if targetRange.contains(ambientIntensity) {
            return 1
        }

        let distance: Double
        if ambientIntensity < targetRange.lowerBound {
            distance = targetRange.lowerBound - ambientIntensity
        } else {
            distance = ambientIntensity - targetRange.upperBound
        }

        return max(0, 1 - (distance / 500))
    }
}
