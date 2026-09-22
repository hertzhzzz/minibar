# 3. Double-Track Click Proxy Service

When a user clicks an icon in the popover, we decided to use a double-track proxy strategy: first attempt an Accessibility action (`kAXShowMenuAction` or `kAXPressAction`), and only fall back to synthetic `CGEvent` mouse injection with a frozen-frame update mask if accessibility fails. Accessibility actions trigger menus natively without moving the user's mouse cursor, while the masked synthetic event ensures compatibility with non-standard status items without visible flickering.

## Considered Options

- **Pure Synthetic CGEvent**: Always warps the hardware mouse cursor to the physical menu bar, causing visible cursor jumping and potential gesture conflicts.
- **Pure Accessibility Action**: Leaves non-standard or custom AppKit status views unresponsive if they fail to implement the accessibility protocol.
- **Double-Track Hybrid**: Combines instantaneous cursor-free invocation for conforming apps with seamless visual-masked physical click injection for non-standard apps.
