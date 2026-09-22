# 1. Spacer Push for Icon Hiding

macOS provides no public API to hide or remove status items owned by other applications. We decided to use the spacer push technique—inflating a dedicated Divider Item to 10,000 pt—rather than attempting private WindowServer/SkyLight CGS hooks or drawing visual overlay windows over the status bar. This guarantees zero system instability across macOS Sonoma and Sequoia updates and requires no private entitlements.

## Considered Options

- **Private SkyLight / CGS Window Alpha Hooks**: High risk of WindowServer crashes and breakage across point releases.
- **Visual Overlay / Mask Window**: Covers items visually but leaves them physically present underneath, causing hit-test and click-through conflicts.
- **Spacer Push (`NSStatusItem.length = 10,000 pt`)**: Standard, battle-tested AppKit layout behavior that physically pushes items off the visible screen edge.
