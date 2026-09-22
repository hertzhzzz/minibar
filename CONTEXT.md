# MiniBar Domain Context

MiniBar is a native macOS menu bar manager that consolidates, folds, and provides rapid access to third-party and select system status items to prevent clutter and hardware notch obstruction.

## Language

### Core Components

**Control Item**:
The primary permanent status bar icon owned by MiniBar that toggles the popover interface.
_Avoid_: Toggle button, trigger icon, anchor icon

**Divider Item**:
The invisible status bar item positioned immediately to the left of the Control Item, whose width expands to push managed items off-screen.
_Avoid_: Spacer, blocker, separator, dummy item

**Managed Item**:
A third-party or movable system status bar item that MiniBar can reorder across the Divider Item or display within its popover.
_Avoid_: Target item, foreign icon, child item

**Immovable Item**:
A system-owned status bar item (specifically Clock and Control Center BentoBox) whose position is locked by WindowServer and cannot be moved or hidden.
_Avoid_: Protected item, locked icon, permanent item

### Modes and States

**Folded State**:
The operational state where the Divider Item is inflated to push managed items outside the screen's visible bounds.
_Avoid_: Collapsed, hidden mode, compressed

**Expanded State**:
The operational state where the popover panel is visible beneath the Control Item, displaying managed items.
_Avoid_: Open mode, show mode

**Arrange Mode**:
The configuration state within the popover where clicking a managed item migrates it across the Divider Item.
_Avoid_: Edit mode, layout mode, settings mode

**Pinned**:
The state of a managed item that remains in the visible menu bar to the right of the Divider Item.
_Avoid_: Kept, visible, top bar item

**Unpinned**:
The state of a managed item that is pushed off-screen to the left of the Divider Item and accessed via the popover.
_Avoid_: Hidden, folded, tucked

### Interactions and Mechanisms

**Spacer Push**:
The layout technique of setting an `NSStatusItem`'s length to an extreme value (10,000 pt) so WindowServer pushes items to its left off-screen.
_Avoid_: Window masking, alpha hiding, overlay hiding

**Click Proxy**:
The mechanism of relaying a user click in the popover to the underlying status item via Accessibility actions or synthetic events.
_Avoid_: Event forwarding, click through, simulated press

**Update Mask**:
A temporary single-frame snapshot panel that covers the menu bar during physical icon movements to prevent visual flicker.
_Avoid_: Cover window, screen freezer, black bar
