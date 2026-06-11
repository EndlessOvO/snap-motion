import CoreImage
import CoreVideo
import Foundation

struct ImageSharpnessEvaluator {
    private let context = CIContext()

    func score(pixelBuffer: CVPixelBuffer) -> Double {
        score(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
    }

    func score(ciImage image: CIImage) -> Double {
        let extent = image.extent
        guard !extent.isEmpty,
              let edges = CIFilter(
                name: "CIEdges",
                parameters: [
                    kCIInputImageKey: image,
                    kCIInputIntensityKey: 1.0
                ]
              )?.outputImage
        else {
            return 0.6
        }

        let average = edges
            .cropped(to: extent)
            .applyingFilter(
                "CIAreaAverage",
                parameters: [kCIInputExtentKey: CIVector(cgRect: extent)]
            )

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            average,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let averageEdge = (Double(bitmap[0]) + Double(bitmap[1]) + Double(bitmap[2])) / (3 * 255)
        return (averageEdge * 3.5).clamped(to: 0...1)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
