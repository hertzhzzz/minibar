import Foundation
import CoreGraphics

extension CGImage {
    /// Trims transparent borders where alpha <= alphaThreshold (default: 12).
    /// Returns nil if the entire image is transparent or has 0 dimensions.
    /// Returns self if the non-transparent bounding box equals the full image.
    public func trimmingTransparentBorder(alphaThreshold: UInt8 = 12) -> CGImage? {
        let width = self.width
        let height = self.height

        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var maxX = -1
        var minY = height
        var maxY = -1

        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let alpha = rawData[rowOffset + x * bytesPerPixel + 3]
                if alpha > alphaThreshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        // Entire image is transparent below the threshold
        guard maxX >= minX, maxY >= minY else {
            return nil
        }

        // If the bounding rect matches the full image bounds, no crop needed
        if minX == 0 && minY == 0 && maxX == width - 1 && maxY == height - 1 {
            return self
        }

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        return self.cropping(to: cropRect)
    }
}
