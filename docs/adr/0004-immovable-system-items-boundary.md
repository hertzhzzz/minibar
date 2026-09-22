# 4. Immovable System Items Scope Boundary

In macOS 15 Sequoia, WindowServer strictly enforces that the Clock and Control Center (`BentoBox`) status items cannot be repositioned via `⌘ + Drag` and cannot be moved across a status item divider. We decided to explicitly mark Clock and Control Center as immovable and exclude them from being managed or folded, while allowing movable system items (Battery and Wi-Fi) alongside third-party application icons. This avoids failed synthetic drag gestures and respects macOS system boundaries.

## Considered Options

- **Attempting to force-hide Clock/ControlCenter**: Requires unsafe private SkyLight APIs that trigger WindowServer crashes on macOS 15.
- **Excluding all Apple system items**: Overly restrictive; leaves battery and Wi-Fi permanently taking up valuable notch-adjacent space even though they are legally movable.
- **Selective exclusion**: Explicitly lock Clock and BentoBox to the rightmost visible bar, while allowing Battery, Wi-Fi, and all third-party items to be managed.
