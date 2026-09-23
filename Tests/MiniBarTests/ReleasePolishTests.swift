import Foundation
import Testing

private let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

struct ReleasePolishTests {
    @Test func makefile_declaresTestAppAndRunTargets() throws {
        let text = try String(
            contentsOf: repoRoot.appendingPathComponent("Makefile"),
            encoding: .utf8
        )
        #expect(text.contains("\ntest:"))
        #expect(text.contains("\napp:"))
        #expect(text.contains("\nrun:"))
    }

    @Test func infoPlist_isAccessoryAppWithoutNetworkExceptions() throws {
        let text = try String(
            contentsOf: repoRoot.appendingPathComponent("Resources/Info.plist"),
            encoding: .utf8
        )
        #expect(text.contains("<key>LSUIElement</key>"))
        #expect(text.contains("<true/>"))
        #expect(!text.contains("NSAppTransportSecurity"))
        #expect(!text.contains("NSAllowsArbitraryLoads"))
    }

    @Test func appIcon_assetExists() {
        let icon = repoRoot.appendingPathComponent("Resources/AppIcon.icns")
        #expect(FileManager.default.fileExists(atPath: icon.path))
    }

    @Test func sources_doNotImportNetworkStacks() throws {
        let sources = repoRoot.appendingPathComponent("Sources/MiniBar")
        let files = try FileManager.default.contentsOfDirectory(
            at: sources,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "swift" }

        #expect(!files.isEmpty)

        let forbidden = [
            "import Network",
            "import WebKit",
            "import CFNetwork",
            "URLSession",
            "WKWebView"
        ]

        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for token in forbidden {
                #expect(
                    !text.contains(token),
                    "\(file.lastPathComponent) must not contain \(token)"
                )
            }
        }
    }
}
