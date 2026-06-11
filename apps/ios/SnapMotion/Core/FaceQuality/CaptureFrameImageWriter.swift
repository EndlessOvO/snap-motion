import CoreImage
import CoreVideo
import Foundation
import UIKit

struct CaptureFrameImageWriter {
    private let fileManager: FileManager
    private let context = CIContext()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func write(pixelBuffer: CVPixelBuffer, slot: CaptureSlot, timestamp: Date = Date()) throws -> URL {
        try writeJPEG(ciImage: CIImage(cvPixelBuffer: pixelBuffer), slot: slot, timestamp: timestamp.timeIntervalSince1970)
    }

    func writeJPEG(ciImage image: CIImage, slot: CaptureSlot, timestamp: TimeInterval) throws -> URL {
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw CaptureFrameImageWriterError.imageEncodingFailed
        }

        let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
        guard let data = uiImage.jpegData(compressionQuality: 0.82) else {
            throw CaptureFrameImageWriterError.imageEncodingFailed
        }

        let directory = fileManager.temporaryDirectory
            .appending(path: "SnapMotionCapture", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileName = "\(slot.rawValue)-\(Int(timestamp * 1000)).jpg"
        let url = directory.appending(path: fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }
}

enum CaptureFrameImageWriterError: Error, LocalizedError {
    case imageEncodingFailed

    var errorDescription: String? {
        "Could not save the captured frame."
    }
}
