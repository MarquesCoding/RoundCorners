# RoundCorners

A tiny macOS menu-bar app that rounds the square bottom corners of a MacBook display to match the hardware-rounded top corners. On the 2026 MacBook Pro with PROLED XDR display, all four corners are rounded the same way.

## Build & run

```sh
./build.sh
open build/RoundCorners.app
```

Requires macOS 26+ and a Swift 6 toolchain.

## Usage

- **Radius:** defaults to 26 pt with Apple's continuous (squircle) curve.
- **Calibrate:** draws a red guide on the top corners. Lower the radius until the line just disappears behind the physical edge; the bottom corners then match your hardware.
- **Options:** round the top corners too (useful on external displays), limit to the built-in display, and launch at login. For launch at login to work best, move the app to `/Applications`.

The mask is a click-through black overlay above the menu bar, the Dock, and full-screen apps. It does appear in screenshots and screen recordings.
