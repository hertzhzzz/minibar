import Foundation
import CoreGraphics

/// Raw dictionary dictionary describing a window from `CGWindowListCopyWindowInfo`.
public typealias WindowInfoDictionary = [String: Sendable]

/// Seam for enumerating window server windows so scanner logic can be unit-tested without WindowServer.
public protocol WindowListProviding: Sendable {
    func copyWindowInfoList() -> [[String: Any]]
}

/// Seam for capturing a window image so capture logic can be mocked/unit-tested.
public protocol WindowImageCapturing: Sendable {
    func captureImage(for window: StatusItemWindow) -> CGImage?
}

/// Standard production implementation that queries WindowServer via CoreGraphics.
public final class SystemWindowListProvider: WindowListProviding {
    public init() {}

    public func copyWindowInfoList() -> [[String: Any]] {
        guard let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return list
    }
}

/// Dynamic function signature matching `CGWindowListCreateImage` to bypass macOS 15 SDK deprecation compile errors.
private typealias CGWindowListCreateImageFunc = @convention(c) (
    CGRect,
    CGWindowListOption,
    CGWindowID,
    CGWindowImageOption
) -> CGImage?

/// Standard production icon capture implementation using dynamic linking to `CGWindowListCreateImage`.
public final class SystemWindowImageCapturer: WindowImageCapturing {
    private let captureFunc: CGWindowListCreateImageFunc?

    public init() {
        if let handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_NOW),
           let sym = dlsym(handle, "CGWindowListCreateImage") {
            self.captureFunc = unsafeBitCast(sym, to: CGWindowListCreateImageFunc.self)
        } else {
            self.captureFunc = nil
        }
    }

    public func captureImage(for window: StatusItemWindow) -> CGImage? {
        guard let captureFunc = captureFunc else { return nil }

        // kCGWindowImageBoundsIgnoreFraming (1) | kCGWindowImageBestResolution (256) = 257
        let options = CGWindowImageOption(rawValue: 1 | 256)

        // Passing window.bounds in screen coordinates produces 2x Retina resolution on Retina displays
        let screenRect = window.bounds
        let rawImage = captureFunc(screenRect, .optionIncludingWindow, window.windowID, options)
            ?? captureFunc(.null, .optionIncludingWindow, window.windowID, options)

        return rawImage?.trimmingTransparentBorder(alphaThreshold: 12)
    }
}

/// In-memory cache for storing trimmed Retina bitmaps of status bar icons.
public final class IconCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [CGWindowID: CGImage] = [:]

    public init() {}

    public func image(for windowID: CGWindowID) -> CGImage? {
        lock.lock()
        defer { lock.unlock() }
        return storage[windowID]
    }

    public func setImage(_ image: CGImage, for windowID: CGWindowID) {
        lock.lock()
        defer { lock.unlock() }
        storage[windowID] = image
    }

    public func removeImage(for windowID: CGWindowID) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: windowID)
    }

    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}

/// Scans and classifies macOS status bar windows (`layer == 25`).
public final class MenuBarScanner: Sendable {
    private let windowProvider: WindowListProviding
    private let imageCapturer: WindowImageCapturing
    public let iconCache: IconCache

    public init(
        windowProvider: WindowListProviding = SystemWindowListProvider(),
        imageCapturer: WindowImageCapturing = SystemWindowImageCapturer(),
        iconCache: IconCache = IconCache()
    ) {
        self.windowProvider = windowProvider
        self.imageCapturer = imageCapturer
        self.iconCache = iconCache
    }

    /// Evaluates whether a status item window is strictly immovable according to ADR 0004.
    /// In macOS 15, WindowServer locks Clock and Control Center BentoBox to the far right.
    public static func isImmovable(ownerName: String, title: String) -> Bool {
        let isControlCentre = ownerName == "Control Centre" || ownerName == "ControlCenter"
        if isControlCentre {
            if title == "Clock" || title.hasPrefix("BentoBox") {
                return true
            }
        }
        return false
    }

    /// Scans WindowServer windows with layer == 25, categorizing them into managed items and immovable items.
    /// Excludes windows owned by the current process (MiniBar's own Control & Divider items).
    public func scanStatusWindows() -> (managed: [StatusItemWindow], immovable: [StatusItemWindow]) {
        let rawWindows = windowProvider.copyWindowInfoList()
        let currentPID = ProcessInfo.processInfo.processIdentifier

        var managed: [StatusItemWindow] = []
        var immovable: [StatusItemWindow] = []

        for dict in rawWindows {
            guard let layer = dict[kCGWindowLayer as String] as? Int, layer == 25 else {
                continue
            }

            let pid = dict[kCGWindowOwnerPID as String] as? pid_t ?? 0
            if pid == currentPID {
                continue // Ignore MiniBar's own status items
            }

            let windowID = dict[kCGWindowNumber as String] as? CGWindowID ?? 0
            let ownerName = dict[kCGWindowOwnerName as String] as? String ?? ""
            let title = dict[kCGWindowName as String] as? String ?? ""

            let boundsDict = dict[kCGWindowBounds as String] as? [String: Any] ?? [:]
            let x = boundsDict["X"] as? CGFloat ?? 0
            let y = boundsDict["Y"] as? CGFloat ?? 0
            let width = boundsDict["Width"] as? CGFloat ?? 0
            let height = boundsDict["Height"] as? CGFloat ?? 0
            let bounds = CGRect(x: x, y: y, width: width, height: height)

            let immovableStatus = Self.isImmovable(ownerName: ownerName, title: title)

            let item = StatusItemWindow(
                windowID: windowID,
                ownerPID: pid,
                ownerName: ownerName,
                title: title,
                bounds: bounds,
                isImmovable: immovableStatus
            )

            if immovableStatus {
                immovable.append(item)
            } else {
                managed.append(item)
            }
        }

        return (managed: managed, immovable: immovable)
    }

    /// Retrieves an icon image for the given window, querying the cache first and falling back to capture.
    public func icon(for window: StatusItemWindow) -> CGImage? {
        if let cached = iconCache.image(for: window.windowID) {
            return cached
        }

        guard let captured = imageCapturer.captureImage(for: window) else {
            return nil
        }

        iconCache.setImage(captured, for: window.windowID)
        return captured
    }
}
