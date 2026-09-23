import SwiftUI
import CoreGraphics

/// Represents a single displayable status item in the popover grid.
public struct PopoverItemViewModel: Identifiable, Sendable {
    public let id: CGWindowID
    public let title: String
    public let ownerName: String
    public let icon: CGImage?

    public init(id: CGWindowID, title: String, ownerName: String, icon: CGImage?) {
        self.id = id
        self.title = title
        self.ownerName = ownerName
        self.icon = icon
    }

    public var displayName: String {
        if !ownerName.isEmpty { return ownerName }
        if !title.isEmpty { return title }
        return "Unknown"
    }
}

/// SwiftUI Popover grid view that displays captured status item icons in a 4-column layout.
public struct PopoverGridView: View {
    public let items: [PopoverItemViewModel]
    public let onItemClicked: ((PopoverItemViewModel) -> Void)?

    private let columns = [
        GridItem(.adaptive(minimum: 38, maximum: 44), spacing: 8)
    ]

    public init(
        items: [PopoverItemViewModel],
        onItemClicked: ((PopoverItemViewModel) -> Void)? = nil
    ) {
        self.items = items
        self.onItemClicked = onItemClicked
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MiniBar")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(items.count) items")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.horizontal, 4)

            if items.isEmpty {
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
                    ForEach(items) { item in
                        Button(action: {
                            onItemClicked?(item)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.primary.opacity(0.05))
                                    .frame(width: 38, height: 38)

                                if let cgImage = item.icon {
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
                        }
                        .buttonStyle(.plain)
                        .help("\(item.displayName)")
                    }
                }
            }
        }
        .padding(12)
        .frame(minWidth: 190, maxWidth: 220)
        .background(.ultraThinMaterial)
    }
}
