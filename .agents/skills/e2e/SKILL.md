---
name: e2e
description: Drive the app in an Android emulator or iOS Simulator for manual E2E testing
---

## Setup

### Android emulator (preferred)

Requires a running Android emulator with the app installed.

- Verify connection: run `adb devices`
- Screen resolution: run `adb shell wm size`

### iOS Simulator (fallback)

Requires Xcode Simulator with the app running. Limited to screenshots only via `xcrun simctl` — touch input requires the computer-use MCP (takes over the user's screen).

- Booted devices: run `xcrun simctl list devices booted`

## Tools

### Screenshots

- **Android:** `adb exec-out screencap -p > /tmp/android_screen.png` then `Read` to view
- **iOS:** `xcrun simctl io <UDID> screenshot /tmp/sim_screen.png` then `Read` to view

### UI hierarchy (Android only)

`adb shell uiautomator dump` produces an XML accessibility tree with exact pixel bounds and `content-desc` for every element. This is the primary way to find tap coordinates — do not guess from screenshots.

```bash
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml /tmp/ui.xml
```

Then extract elements:

```bash
grep -oE 'content-desc="[^"]*"[^/]*bounds="[^"]*"' /tmp/ui.xml
```

Flutter widgets with `Semantics` labels appear as `content-desc`. The bounds format is `[left,top][right,bottom]` in pixels. Tap the center: `x = (left+right)/2`, `y = (top+bottom)/2`.

### Touch input (Android only)

- **Tap:** `adb shell input tap <x> <y>`
- **Swipe:** `adb shell input swipe <x1> <y1> <x2> <y2> <duration_ms>`
- **Key event:** `adb shell input keyevent <code>` (BACK=4, HOME=3, ENTER=66)
- **Text:** `adb shell input text '<text>'`

### Scrollable containers

Swiping on a `TabBarView` body switches tabs. Swiping on a `SingleChildScrollView`/`HorizontalScrollView` scrolls it. The `uiautomator` dump shows `scrollable="true"` on scrollable containers — use those bounds for swipe coordinates.

## Workflow

1. **Take a screenshot** to see current app state
2. **Dump UI hierarchy** with `uiautomator` to get element bounds
3. **Find the target element** by `content-desc` or position in the tree
4. **Calculate center coordinates** from bounds and tap
5. **Screenshot again** to verify the result
6. Repeat until the task is complete

Always dump the UI hierarchy before tapping — never guess coordinates from screenshots alone. Re-dump after each navigation since bounds change between screens.
