# AlienFX for macOS v1.0 — Area-51m R2 Daily Driver

A lightweight macOS menu-bar controller for the Alienware Area-51m R2.

This build is intentionally designed around one rule:

> **The Windows / Alienware Command Center per-key RGB layout is the protected baseline.**

The macOS UI does **not** expose per-key RGB writes or global RGB effects. It only changes hardware brightness. This lets a Windows-created layout (for example, red WASD with different colours on other keys) remain the keyboard's colour layout while macOS controls brightness, sleep/wake behaviour, lock behaviour and power-source presets.

## Supported hardware in this project

- Keyboard: VID `0x0D62`, PID `0x1A1C`, AlienFX API v5, 64-byte HID report
- Chassis / logo / Tron lights: VID `0x187C`, PID `0x0550`, AlienFX API v4, 34-byte HID report

These IDs are hard-coded for the Area-51m R2 configuration this repository targets.

## Daily-driver features

- Native macOS menu-bar app (`LSUIElement`, no Dock icon)
- Live keyboard brightness slider
- Live chassis/logo brightness slider
- HID writes throttled to 80 ms while dragging (~12.5 updates/sec)
- Persistent brightness and preferences
- Brightness-only presets:
  - Daily
  - Focus
  - Night
  - Movie
  - Lights Off
- Save current brightness values back into Daily / Focus / Night / Movie
- Display sleep automation: turn both light groups off and restore afterward
- Session lock automation: turn both light groups off and restore afterward
- Optional Battery Saver with user-saveable keyboard/chassis brightness
- Event-driven AC/battery detection through IOKit (no polling loop)
- Sleep/wake HID teardown and delayed reconnect with retries
- Manual Reconnect AlienFX
- Launch at Login via `SMAppService` (macOS 13+)
- Global keyboard-brightness shortcuts: `Control+Option+F5` / `Control+Option+F6` (−/+ 10%)
- Copy Diagnostics to clipboard with visual confirmation
- No continuous background timer

## RGB safety model

The public macOS bridge deliberately exposes only:

- `setKeyboardBrightness:`
- `setChassisBrightness:`

It does not expose SDK calls such as `SetColor`, `SetMultiColor`, `SetAction` or `SetGlobalEffects` to the app UI.

The low-level SDK still contains those legacy functions because it originated from AlienFX Tools, but this app does not call them. Do not add a new RGB UI until the Windows/AWCC per-key profile can be captured and replayed reliably.

If Windows lighting ever looks wrong after experimental HID work, a reboot followed by AWCC applying the saved profile should restore the hardware baseline. The daily-driver build itself does not intentionally issue RGB commands.

## HID stability fixes in this version

The original macOS port had several Windows-to-POSIX / IOKit issues. This version fixes the ones that matter for a long-running menu-bar app:

- HID matching now includes **both** Vendor ID and Product ID (the old dictionary accidentally contained only one key)
- IOKit callbacks use the callback `context` correctly instead of casting `sender`
- Removed an input-report callback buffer allocation that leaked memory and was not used
- `CFNumber`, matching dictionary and device set objects are released correctly
- `IOHIDManager` is unscheduled, closed and released on teardown
- Reinitialization first closes an existing manager, preventing duplicate run-loop registrations
- `ToggleState` no longer dereferences a null mapping object
- Windows-style `Sleep(5/50/100)` delays are now true millisecond delays instead of POSIX `sleep()` seconds
- Removed per-HID-packet console spam

## Build

Requirements:

- macOS 13 or later
- Current Xcode
- Area-51m R2 hardware matching the VID/PID above

Open `AlienFxTest.xcodeproj` in Xcode and build the `AlienFxTest` scheme, or simply run:

```bash
./build-release.sh
```

The script places the release build at:

```text
build/Build/Products/Release/AlienFX.app
```

This source package intentionally does **not** include the repository's old prebuilt `AlienFxTest.app`, so there is no risk of accidentally launching the 2023 binary instead of the modified build.

For **Launch at Login**, move the built app to `/Applications` (or `~/Applications`) and launch it from there before enabling the option. The app now detects when it is being run directly from the Xcode build folder and explains why Login Items cannot be enabled reliably from there. macOS may still require approval in System Settings > General > Login Items.

## Recommended first test

1. Boot Windows and confirm the desired AWCC per-key layout is correct.
2. Reboot into macOS.
3. Launch this app. The colours should remain the same.
4. Drag Keyboard Brightness. Only intensity should change; per-key colours should remain unchanged.
5. Try `Lights Off`, then `Daily`. The same per-key colour layout should reappear at the selected brightness.
6. Test display sleep/wake and lock/unlock.
7. Test the global keyboard shortcuts: `Control+Option+F5` decreases keyboard brightness by 10%, `Control+Option+F6` increases it by 10%.
8. Finally test a normal computer sleep/wake and copy Diagnostics if either AlienFX device does not reconnect.

## Credits

The low-level AlienFX SDK was originally ported from [T-Troll/alienfx-tools](https://github.com/T-Troll/alienfx-tools). The original macOS Area-51m R2 project was created by `kingo132`.


## v1.0 polish

- Shorter status text: `Colors: Windows/AWCC · preserved`
- Profile/effective-brightness status uses a more readable secondary label color
- Launch at Login diagnostics now report `On`, `Off`, or `Needs approval` instead of the raw ServiceManagement `not found` state
- Running outside Applications is detected and explained before enabling Launch at Login
- Global keyboard-brightness hotkeys use Carbon `RegisterEventHotKey`, so they do not require Accessibility/Input Monitoring permissions
- Diagnostics include the app version and hotkey configuration and briefly show `Diagnostics Copied ✓` after copying
