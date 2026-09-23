import Foundation
import CoreGraphics
import Testing
@testable import MiniBar

struct AlphaTrimTests {
    private func makeImage(width: Int, height: Int, fillPixels: (Int, Int) -> UInt8) -> CGImage? {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)

        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let alpha = fillPixels(x, y)
                data[rowOffset + x * bytesPerPixel + 0] = alpha > 0 ? 255 : 0 // R
                data[rowOffset + x * bytesPerPixel + 1] = alpha > 0 ? 255 : 0 // G
                data[rowOffset + x * bytesPerPixel + 2] = alpha > 0 ? 255 : 0 // B
                data[rowOffset + x * bytesPerPixel + 3] = alpha               // A
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }

        return ctx.makeImage()
    }

    @Test func allTransparent_returnsNil() {
        guard let image = makeImage(width: 10, height: 10, fillPixels: { _, _ in 0 }) else {
            Issue.record("Failed to create image")
            return
        }

        let trimmed = image.trimmingTransparentBorder(alphaThreshold: 12)
        #expect(trimmed == nil)
    }

    @Test func allOpaque_returnsSelfWithoutCropping() {
        guard let image = makeImage(width: 10, height: 10, fillPixels: { _, _ in 255 }) else {
            Issue.record("Failed to create image")
            return
        }

        let trimmed = image.trimmingTransparentBorder(alphaThreshold: 12)
        #expect(trimmed != nil)
        #expect(trimmed?.width == 10)
        #expect(trimmed?.height == 10)
    }

    @Test func centeredIsland_isCorrectlyCropped() {
        // 10x10 image with a 2x2 opaque island at x: 4...5, y: 4...5
        guard let image = makeImage(width: 10, height: 10, fillPixels: { x, y in
            (x >= 4 && x <= 5 && y >= 4 && y <= 5) ? 255 : 0
        }) else {
            Issue.record("Failed to create image")
            return
        }

        let trimmed = image.trimmingTransparentBorder(alphaThreshold: 12)
        #expect(trimmed != nil)
        #expect(trimmed?.width == 2)
        #expect(trimmed?.height == 2)
    }

    @Test func alphaThreshold_strictlyExcludes12_andIncludes13() {
        // At threshold 12, alpha <= 12 is treated as transparent
        guard let image12 = makeImage(width: 6, height: 6, fillPixels: { _, _ in 12 }) else {
            Issue.record("Failed to create image")
            return
        }
        #expect(image12.trimmingTransparentBorder(alphaThreshold: 12) == nil)

        // Alpha 13 is treated as non-transparent
        guard let image13 = makeImage(width: 6, height: 6, fillPixels: { x, y in
            (x == 2 && y == 2) ? 13 : 12
        }) else {
            Issue.record("Failed to create image")
            return
        }
        let trimmed13 = image13.trimmingTransparentBorder(alphaThreshold: 12)
        #expect(trimmed13 != nil)
        #expect(trimmed13?.width == 1)
        #expect(trimmed13?.height == 1)
    }
}
