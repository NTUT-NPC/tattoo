---
name: e2e
description: Drive the app in an Android emulator for manual E2E testing
---

## Setup

### Android emulator

- Launch the app with `flutter run` (in the background) so logs are inspectable and the running build reflects the current code
- Run `adb devices` once to see what's attached:
  - **One device:** plain `adb` and the helper scripts below work as-is.
  - **Multiple devices:** target the emulator on every call. Use `adb -s <serial> ...` for raw `adb`, and prefix `ANDROID_SERIAL=<serial>` on the same command line for the helper scripts (e.g. `ANDROID_SERIAL=emulator-5554 .agents/skills/e2e/scripts/screencap.sh`). `export ANDROID_SERIAL=<serial>` only works *within a single persistent shell session* — it does not carry across separate shell tool calls, so don't use it as your default targeting strategy.
  - All `adb …` examples below assume the single-device case; in the multi-device case, add `-s <serial>` (or the equivalent helper-script prefix) to each one.
- Screen resolution: `adb shell wm size`

### Login credentials

If a flow needs login, look for project-local Dart test credentials in `test/test_config.json` under the current workspace. Do not copy credentials into this skill or into permanent notes.

## Tools

### Screenshots

Use the helper script — it captures, resizes, and writes the PNG in one call:

```bash
.agents/skills/e2e/scripts/screencap.sh             # writes /tmp/screen.png
.agents/skills/e2e/scripts/screencap.sh /tmp/x.png  # custom output path
```

Then read the PNG with the agent's image tool.

### UI hierarchy

The UI accessibility tree gives exact pixel bounds and `content-desc` for every element. This is the primary way to find tap coordinates — do not guess from screenshots.

```bash
.agents/skills/e2e/scripts/uidump.sh             # writes /tmp/ui.xml, prints element summary
.agents/skills/e2e/scripts/uidump.sh /tmp/x.xml  # custom output path
```

The script streams `uiautomator dump /dev/tty` over `adb exec-out` and writes the full XML to the output path. It then prints a compact one-line-per-element summary of the nodes worth tapping or reading: any node with non-empty `text` or `content-desc`, or with any of `clickable` / `scrollable` / `selected` / `focused` / `password` set to `true`. Each line shows `bounds`, the short class name, `text="..."` and/or `desc="..."` when present, and the list of true states. Long values are whitespace-collapsed and truncated to ~120 chars.

Use the printed summary as the primary input for choosing tap coordinates — it covers the vast majority of cases. Fall back to searching `/tmp/ui.xml` directly (e.g. with `grep`) when you need parent/child structure or attributes the summary doesn't include (`resource-id`, `package`, `checked`, `enabled`, etc.).

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
# (assumes the value contains no single quotes; if it does, replace each ' with '\'' or use a different quoting strategy)
adb shell "input text '$PASSWORD'"
```

Tapping a non-empty field places the cursor somewhere inside the existing text — usually but not always at the end. The next `input text` appends rather than replaces. Move the cursor explicitly, backspace, then re-dump the XML to confirm the field is empty before typing:

```bash
adb shell input tap <x> <y>
adb shell input keyevent 123                                # 123 = MOVE_END (cursor to end of field)
for i in $(seq 1 50); do adb shell input keyevent 67; done  # 67  = DEL/backspace
.agents/skills/e2e/scripts/uidump.sh                        # verify the field is empty
```

Password fields hide their contents, so the only way to verify what was typed is the bullet count — count it against the expected length before submitting.

### Keyboard and focus shifts

- The soft keyboard pushes the layout, so bounds dumped before it opens are stale. Re-dump the UI hierarchy after focusing a text field, after dismissing the keyboard, or after any visible layout change — don't reuse coordinates from across a keyboard transition.
- `keyevent 4` (BACK) is context-dependent: it dismisses the keyboard if open, then closes the topmost picker/dialog, then pops the current route, then exits to the launcher from the root route. Don't chain BACK presses blindly — verify the resulting state (UI dump or screenshot) between presses.

### Scrollable containers

Swiping on a `TabBarView` body switches tabs. Swiping on a `SingleChildScrollView`/`HorizontalScrollView` scrolls it. The `uiautomator` dump shows `scrollable="true"` on scrollable containers — use those bounds for swipe coordinates.

## Workflow

1. **Dump UI hierarchy** with `uiautomator` to get element bounds
2. **Find the target element** by `content-desc` or position in the tree
3. **Calculate center coordinates** from bounds and tap
4. **Verify the resulting state** — UI dump or screenshot, depending on what changed (see below)
5. Repeat until the task is complete

Bounds in the XML are exact pixels — that's where tap coordinates come from. Re-dump after each navigation since bounds change between screens.

**XML vs screenshot for verification.** Default to a fresh UI dump — it's cheaper and exact. Reach for a screenshot only when the change is genuinely visual:

- Use the **XML dump** to confirm: which elements are tappable and where, snackbar/dialog text, selected state of a picker or toggle, password bullet count, whether a field is empty.
- Use a **screenshot** to confirm: image/avatar content, overlay or bottom-sheet stacking, anything where the XML reads "fine" but the visual state is in doubt, and final verification once the goal is met.

**Don't be misled by unrelated dialogs.** In debug builds, async failures (e.g. Google Fonts network errors) can pop a Flutter error dialog on top of an otherwise-successful flow — the underlying state may have updated correctly behind it. Read the dialog text before treating it as a failure of the current step.

**Stop when the goal is achieved.** Don't keep tapping to tidy up UI state (closing menus, navigating back to a home screen) unless the user asked for that — extra taps risk breaking the verified end state.
