# 2. Popover Grid Drawer Interface

To present folded items, we decided to use a compact 4-column frosted glass Popover anchored directly below the MiniBar Control Item, rather than an auxiliary horizontal floating bar positioned underneath the physical MacBook notch. This keeps the interaction focused, avoids interfering with window title bars or video playback beneath the notch, and provides a familiar macOS menu-style dismissal behavior.

## Considered Options

- **Horizontal Floating Notch Capsule**: Suspended directly below the notch; requires complex notch geometry calculations and can block full-screen media or top-window chrome.
- **Dedicated Application Window**: Too heavy and disrupts the user's flow.
- **Anchored Popover Grid**: Native macOS lightweight panel with automatic outside-click dismissal and compact footprint.
