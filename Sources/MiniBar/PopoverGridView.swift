import Combine
import SwiftUI
import CoreGraphics

/// Represents a single displayable status item in the popover grid.
public struct PopoverItemViewModel: Identifiable, Sendable {
    public let id: CGWindowID
    public let title: String
    public let ownerName: String
    public let icon: CGImage?
    public let pinState: PinState

    public init(
        id: CGWindowID,
        title: String,
        ownerName: String,
        icon: CGImage?,
        pinState: PinState = .unpinned
    ) {
        self.id = id
        self.title = title
        self.ownerName = ownerName
        self.icon = icon
        self.pinState = pinState
    }

    public var displayName: String {
        if !ownerName.isEmpty { return ownerName }
        if !title.isEmpty { return title }
        return "Unknown"
    }
}

/// Observable session state for the popover grid, including Arrange Mode.
@MainActor
public final class PopoverContentModel: ObservableObject {
    @Published public var items: [PopoverItemViewModel]
    @Published public var isArrangeMode: Bool
    @Published public var busyWindowID: CGWindowID?
    @Published public var isLaunchAtLogin: Bool

    public init(
        items: [PopoverItemViewModel] = [],
        isArrangeMode: Bool = false,
        busyWindowID: CGWindowID? = nil,
        isLaunchAtLogin: Bool = false
    ) {
        self.items = items
        self.isArrangeMode = isArrangeMode
        self.busyWindowID = busyWindowID
        self.isLaunchAtLogin = isLaunchAtLogin
    }
}

/// SwiftUI Popover grid view that displays captured status item icons in a 4-column layout.
public struct PopoverGridView: View {
    @ObservedObject public var model: PopoverContentModel
    public let onItemClicked: ((PopoverItemViewModel) -> Void)?
    public let onLaunchAtLoginChanged: ((Bool) -> Void)?
    public let onQuit: (() -> Void)?

    private let columns = [
        GridItem(.adaptive(minimum: 38, maximum: 44), spacing: 8)
    ]

    public init(
        model: PopoverContentModel,
        onItemClicked: ((PopoverItemViewModel) -> Void)? = nil,
        onLaunchAtLoginChanged: ((Bool) -> Void)? = nil,
        onQuit: (() -> Void)? = nil
    ) {
        self.model = model
        self.onItemClicked = onItemClicked
        self.onLaunchAtLoginChanged = onLaunchAtLoginChanged
        self.onQuit = onQuit
    }

    private var displayedItems: [PopoverItemViewModel] {
        ItemLayout.visibleItems(model.items, arrangeMode: model.isArrangeMode)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MiniBar")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("Arrange", isOn: $model.isArrangeMode)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.system(size: 10))
                    .disabled(model.busyWindowID != nil)
            }
            .padding(.horizontal, 4)

            if displayedItems.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text("No managed status items detected")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(displayedItems) { item in
                        Button(action: {
                            onItemClicked?(item)
                        }) {
                            iconCell(for: item)
                        }
                        .buttonStyle(.plain)
                        .disabled(model.busyWindowID != nil)
                        .help("\(item.displayName)")
                    }
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: Binding(
                get: { model.isLaunchAtLogin },
                set: { onLaunchAtLoginChanged?($0) }
            ))
            .toggleStyle(.checkbox)
            .font(.system(size: 11))
            .padding(.horizontal, 4)

            Button("Quit MiniBar") {
                onQuit?()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)
        }
        .padding(12)
        .frame(minWidth: 190, maxWidth: 220)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func iconCell(for item: PopoverItemViewModel) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.05))

            if model.busyWindowID == item.id {
                ProgressView()
                    .controlSize(.small)
            } else if let cgImage = item.icon {
                Image(decorative: cgImage, scale: 2.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 38, height: 38)
        .overlay(alignment: .bottomTrailing) {
            if model.isArrangeMode {
                Circle()
                    .fill(item.pinState == .pinned ? Color.blue : Color.gray)
                    .frame(width: 7, height: 7)
                    .padding(4)
                    .accessibilityLabel(item.pinState == .pinned ? "Pinned" : "Unpinned")
            }
        }
    }
}
