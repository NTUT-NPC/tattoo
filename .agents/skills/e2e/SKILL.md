---
name: e2e
description: Drive the app in an Android emulator for manual E2E testing
---

## Setup

### Android emulator

- Launch the app with `flutter run` (in the background) so logs are inspectable and the running build reflects the current code
- If `adb devices` lists more than one device, pick the emulator and pass `-s <serial>` to every `adb` call
- Screen resolution: `adb -s <serial> shell wm size`

### Login credentials

If a flow needs login, look for project-local Dart test credentials in `test/test_config.json` under the current workspace. Do not copy credentials into this skill or into permanent notes.

## Tools

### Screenshots

Some AI image APIs reject screenshots with any side longer than 2000px, so always clamp the long edge before reading.

```bash
adb exec-out screencap -p | magick - -resize '1999x1999>' /tmp/android_screen.png
```

Then read the PNG with the agent's image tool.

### UI hierarchy

`adb shell uiautomator dump` produces an XML accessibility tree with exact pixel bounds and `content-desc` for every element. This is the primary way to find tap coordinates — do not guess from screenshots.

```bash
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml /tmp/ui.xml
```

Then extract elements:

```bash
grep -oE 'content-desc="[^"]*"[^/]*bounds="[^"]*"' /tmp/ui.xml
```

Flutter widgets with `Semantics` labels appear as `content-desc`. The bounds format is `[left,top][right,bottom]` in pixels. Tap the center: `x = (left+right)/2`, `y = (top+bottom)/2`.

### Touch input

- **Tap:** `adb shell input tap <x> <y>`
- **Swipe:** `adb shell input swipe <x1> <y1> <x2> <y2> <duration_ms>`
- **Key event:** `adb shell input keyevent <code>` (BACK=4, HOME=3, ENTER=66)
- **Text:** `adb shell input text '<text>'`

### Text input pitfalls

`input text` runs through the device's shell, so any `$`, `#`, backticks, or unquoted whitespace in the value get expanded or word-split there — even after the host shell has already substituted `$PASSWORD`. Failures look like a too-short string in the field.

```bash
# Wrong — host expands $PASSWORD, then the device shell re-parses the value
adb shell input text "$PASSWORD"

# Right — single-quote on the device side so the device shell treats the value literally
adb shell "input text '$PASSWORD'"
```

Tapping a non-empty field places the cursor at the end, so the next `input text` appends rather than replaces. Clear the field first:

```bash
adb shell input tap <x> <y>
for i in $(seq 1 50); do adb shell input keyevent 67; done  # 67 = DEL/backspace
```

Password fields hide their contents, so the only way to verify what was typed is the dot count — count it against the expected length before submitting.

### Scrollable containers

Swiping on a `TabBarView` body switches tabs. Swiping on a `SingleChildScrollView`/`HorizontalScrollView` scrolls it. The `uiautomator` dump shows `scrollable="true"` on scrollable containers — use those bounds for swipe coordinates.

## Workflow

1. **Dump UI hierarchy** with `uiautomator` to get element bounds
2. **Find the target element** by `content-desc` or position in the tree
3. **Calculate center coordinates** from bounds and tap
4. **Screenshot** to confirm the resulting state
5. Repeat until the task is complete

Bounds in the XML are exact pixels — that's where tap coordinates come from. Screenshots are best used as a state check between actions: confirming a screen rendered, an error appeared, or content updated. Re-dump after each navigation since bounds change between screens.
