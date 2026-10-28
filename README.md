# RayguiObjC

A thin Objective-C wrapper around the [raygui](https://github.com/raysan5/raygui)
5.0 control API. raylib is **not** wrapped — Objective-C is a strict superset of
C, so raylib structs (`Rectangle`, `Color`, `Vector2`, `Font`) and functions pass
straight through the boundary. Only the raygui control functions are wrapped.

The wrapper compiles and runs identically on:

- **macOS** — Cocoa Foundation, clang
- **Linux** — GNUstep Foundation, clang/gcc

It depends on Foundation only (`NSString`, `NSObject`). No AppKit types
(`NSRect`, `NSColor`, `NSView`) are used, so the same source links under both
Cocoa and GNUstep without conditional includes. Memory management is manual
retain/release (no ARC) so the same code compiles under GNUstep.

For a complete, from-scratch guide to building a GUI with this wrapper —
the immediate-mode model, every control, styling, and a full example app —
see [MANUAL.md](MANUAL.md). No prior raylib or raygui knowledge is assumed.

## Layout

```
MANUAL.md                    user manual: using the wrapper from scratch (no raylib/raygui knowledge assumed)
VERSIONS.md                  pinned tags + commit SHAs (single source of truth)
TODO.md                      persistent progress log (done vs. pending)
patches/                     cherry-picked upstream fixes (applied to submodules)
vendor/raylib/               submodule, tag 6.0, built statically
vendor/raygui/               submodule, tag 5.0 + hue-bar fix cherry-pick
src/RayguiObjC.h             public header (facade RGGui, RGGResult, RGRectMake)
src/RGGControls.{h,m}        button, label, toggle, checkbox, slider, text box, ...
src/RGGContainers.m          group box, window box, scroll panel, status bar
src/RGGAdvanced.m            list view, color picker, message box, text input, tab bar
src/RGGState.m               styles, font, state, icons
src/RayguiImplementation.m   the ONLY file defining RAYGUI_IMPLEMENTATION
examples/demo/main.m         acceptance harness
tests/                       unit tests + hidden-window smoke test (`make test`)
Makefile                     cross-platform build (dispatches on `uname -s`)
GNUmakefile                  one-line `include Makefile` (GNU make prefers it)
```

## Usage contract

1. Call raygui controls **once per frame, between `BeginDrawing()` and
   `EndDrawing()`**. The wrapper holds no per-control state; raygui reads raylib
   input state and draws via raylib primitives, both invalid outside the frame.
2. All controls take a raylib `Rectangle bounds` first. Use the `RGRectMake(x, y, w, h)`
   helper (mirrors `NSRectMake`).
3. Strings are `NSString` and converted with `UTF8String` per call. Never store
   the returned C pointer.
4. In/out scalars are passed by C pointer — no NSNumber round-trips in the
   per-frame path.
5. Result semantics (raygui 5.0): every control returns an `int` result —
   `1` = pressed, `2` = changed, `>2` = control-specific (e.g. `4` =
   tab-close request). The wrapper exposes this as the `RGGResult` enum.
   **Uniform mechanism:** every interactive control has a `BOOL` convenience
   method (YES = the control reports an interaction) and a `...Raw` variant
   returning the raw `RGGResult`. Exceptions: the purely visual controls
   (`label`, `groupBox`, `panel`, `line`) return `void`; `scrollPanel` returns
   the visible `Rectangle`; the dialogs and `tabBar` return `int`. See
   `src/RayguiObjC.h` for the exact per-control semantics.
6. Wrap each frame's body in a per-frame `@autoreleasepool`. Every control
   call creates autoreleased `NSString`s; under manual retain/release a single
   pool around `main` would accumulate them for the app's lifetime.

## Wrapped controls (raygui 5.0)

All 35 raygui 5.0 control entry points are wrapped across four categories on
the `RGGui` facade (90 class methods total):

| Category | Controls |
| -------- | -------- |
| `RGGui (Controls)` | label, button, labelButton, toggle, toggleGroup, toggleSlider, checkBox, slider, sliderBar, progressBar, textBox, valueBox, valueBoxFloat, comboBox, dropdownBox, spinner, dummyRec, grid |
| `RGGui (Containers)` | windowBox, groupBox, panel, line, scrollPanel, statusBar |
| `RGGui (Advanced)` | listView, colorPicker, colorPanel, colorBarAlpha, colorBarHue, colorPickerHSV, colorPanelHSV, messageBox, textInputDialog, tabBar |
| `RGGui (State)` | enable, disable, lock, unlock, isLocked, setAlpha, setState, state, setFont, font, setStyle, style, loadStyleAtPath, loadStyleDefault, enableTooltip, disableTooltip, setTooltip, iconText, setIconScale, textWidth |

`GuiGetState`/`GuiGetStyle`/`GuiGetTextWidth` are exposed via the State
category. The `NSArray` convenience wrappers join items with `;` and call
raygui's string-based controls; the array-based `GuiListViewEx`/`GuiTabBarEx`
(and the icon/style-from-memory functions) are not wrapped — call them
directly via `#include "raygui.h"` if you need them (see MANUAL.md §9.5).

## Example

```objc
#import "RayguiObjC.h"

// per frame, between BeginDrawing() and EndDrawing():
BOOL clicked = [RGGui button:RGRectMake(10, 10, 120, 30) text:@"Click me"];
BOOL changed = [RGGui checkBox:RGRectMake(10, 50, 20, 20)
                           text:@"Enable thing" checked:&myChecked];
[RGGui slider:RGRectMake(10, 80, 200, 20) text:@"Volume"
        value:&myVolume minValue:0.0f maxValue:1.0f];
```

See `examples/demo/main.m` for a full frame loop (button toggling a checkbox,
slider bound to a float, text box bound to an `NSMutableString`, style file
loaded at startup).

## Building

Pinned versions live in `VERSIONS.md`. Initialize the pinned submodules with
the provided script (it also applies the hue-bar fix to `vendor/raygui` as a
working-tree patch — see VERSIONS.md):

```sh
sh scripts/init-submodules.sh
```

Build raylib statically, then the demo:

```sh
cd vendor/raylib
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_EXAMPLES=OFF
cmake --build build --config Release
cd ../..
```

Both platforms — same command (`make deps` runs the two setup steps above):

```sh
make            # dispatches on `uname -s`: macOS → Cocoa, Linux → GNUstep
make run        # build (if needed) and run the demo
make test       # build and run the tests in tests/
```

`GNUmakefile` is a one-line `include Makefile` (GNU make prefers it), so there
is exactly one copy of the build logic. Each `.m` file is compiled to `.o`
separately (`-x objective-c` applies only to sources), then linked —
`libraylib.a` is never passed through the compiler as source. `-MMD -MP`
tracks header dependencies, so editing `RayguiObjC.h`/`raygui.h`/`raylib.h`
rebuilds what depends on it.

Full build commands, including framework/library flags, are in the makefile.

## Status

See `TODO.md` for the current progress log. The project is finished, pending complete verification by the user.
