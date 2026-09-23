import Foundation
import CoreGraphics
import Testing
@testable import MiniBar

final class MockWindowListProvider: @unchecked Sendable, WindowListProviding {
    let windows: [[String: Any]]

    init(windows: [[String: Any]]) {
        self.windows = windows
    }

    func copyWindowInfoList() -> [[String: Any]] {
        return windows
    }
}

final class MockWindowImageCapturer: @unchecked Sendable, WindowImageCapturing {
    let images: [CGWindowID: CGImage]

    init(images: [CGWindowID: CGImage]) {
        self.images = images
    }

    func captureImage(for window: StatusItemWindow) -> CGImage? {
        return images[window.windowID]
    }
}

struct MenuBarScannerTests {
    private func makeRawWindow(
        windowID: CGWindowID,
        layer: Int,
        ownerPID: pid_t,
        ownerName: String,
        title: String,
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat = 30,
        height: CGFloat = 30
    ) -> [String: Any] {
        return [
            kCGWindowNumber as String: windowID,
            kCGWindowLayer as String: layer,
            kCGWindowOwnerPID as String: ownerPID,
            kCGWindowOwnerName as String: ownerName,
            kCGWindowName as String: title,
            kCGWindowBounds as String: [
                "X": x,
                "Y": y,
                "Width": width,
                "Height": height
            ]
        ]
    }

    private func makeDummyImage() -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var data: [UInt8] = [255, 0, 0, 255]
        guard let ctx = CGContext(
            data: &data,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }
        return ctx.makeImage()
    }

    @Test func scanner_filtersOutNonLayer25Windows() {
        let rawList: [[String: Any]] = [
            makeRawWindow(windowID: 1, layer: 0, ownerPID: 100, ownerName: "Finder", title: "Desktop"),
            makeRawWindow(windowID: 2, layer: 25, ownerPID: 200, ownerName: "Amphetamine", title: "Amphetamine"),
            makeRawWindow(windowID: 3, layer: 26, ownerPID: 300, ownerName: "WindowServer", title: "Overlay")
        ]

        let scanner = MenuBarScanner(windowProvider: MockWindowListProvider(windows: rawList))
        let result = scanner.scanStatusWindows()

        #expect(result.managed.count == 1)
        #expect(result.managed.first?.windowID == 2)
        #expect(result.immovable.isEmpty)
    }

    @Test func scanner_filtersOutMiniBarOwnWindows() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let rawList: [[String: Any]] = [
            makeRawWindow(windowID: 10, layer: 25, ownerPID: currentPID, ownerName: "MiniBar", title: "Item-0"),
            makeRawWindow(windowID: 11, layer: 25, ownerPID: 500, ownerName: "OneDrive", title: "OneDrive")
        ]

        let scanner = MenuBarScanner(windowProvider: MockWindowListProvider(windows: rawList))
        let result = scanner.scanStatusWindows()

        #expect(result.managed.count == 1)
        #expect(result.managed.first?.windowID == 11)
    }

    @Test func immovableItems_clockAndBentoBox_areCategorizedAsImmovable() {
        let rawList: [[String: Any]] = [
            makeRawWindow(windowID: 20, layer: 25, ownerPID: 600, ownerName: "Control Centre", title: "Clock"),
            makeRawWindow(windowID: 21, layer: 25, ownerPID: 600, ownerName: "Control Centre", title: "BentoBox-0"),
            makeRawWindow(windowID: 22, layer: 25, ownerPID: 600, ownerName: "Control Centre", title: "Battery"),
            makeRawWindow(windowID: 23, layer: 25, ownerPID: 600, ownerName: "Control Centre", title: "WiFi"),
            makeRawWindow(windowID: 24, layer: 25, ownerPID: 700, ownerName: "Amphetamine", title: "Amphetamine")
        ]

        let scanner = MenuBarScanner(windowProvider: MockWindowListProvider(windows: rawList))
        let result = scanner.scanStatusWindows()

        #expect(result.immovable.count == 2)
        let immovableIDs = Set(result.immovable.map(\.windowID))
        #expect(immovableIDs.contains(20))
        #expect(immovableIDs.contains(21))

        #expect(result.managed.count == 3)
        let managedIDs = Set(result.managed.map(\.windowID))
        #expect(managedIDs.contains(22)) // Battery is movable
        #expect(managedIDs.contains(23)) // WiFi is movable
        #expect(managedIDs.contains(24)) // Third party is movable
    }

    @Test func iconCache_returnsCachedImageOnSubsequentCalls() {
        guard let dummyImage = makeDummyImage() else {
            Issue.record("Failed to create dummy image")
            return
        }

        let item = StatusItemWindow(
            windowID: 99,
            ownerPID: 1234,
            ownerName: "App",
            title: "App",
            bounds: .zero,
            isImmovable: false
        )

        let capturer = MockWindowImageCapturer(images: [99: dummyImage])
        let iconCache = IconCache()
        let scanner = MenuBarScanner(
            windowProvider: MockWindowListProvider(windows: []),
            imageCapturer: capturer,
            iconCache: iconCache
        )

        #expect(iconCache.image(for: 99) == nil)

        // First call caches the image
        let fetched1 = scanner.icon(for: item)
        #expect(fetched1 === dummyImage)
        #expect(iconCache.image(for: 99) === dummyImage)

        // Subsequent call returns cached image even if capturer has no image anymore
        let scannerWithEmptyCapturer = MenuBarScanner(
            windowProvider: MockWindowListProvider(windows: []),
            imageCapturer: MockWindowImageCapturer(images: [:]),
            iconCache: iconCache
        )
        let fetched2 = scannerWithEmptyCapturer.icon(for: item)
        #expect(fetched2 === dummyImage)
    }

    @Test func scanner_withLiveSystem_canScanWithoutCrashing() {
        let scanner = MenuBarScanner()
        let result = scanner.scanStatusWindows()
        // If there are status items running on this machine, test scanning & capture
        #expect(!result.managed.isEmpty || !result.immovable.isEmpty)

        for immovable in result.immovable {
            #expect(immovable.isImmovable)
            #expect(immovable.title == "Clock" || immovable.title.hasPrefix("BentoBox"))
        }

        for managed in result.managed {
            #expect(!managed.isImmovable)
            // Verify capturing does not crash
            _ = scanner.icon(for: managed)
        }
    }
}
