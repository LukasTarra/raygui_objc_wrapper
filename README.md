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

## Layout

```
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
Makefile                     macOS build
GNUmakefile                  Linux / GNUstep build
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
   `1` = pressed, `2` = changed, `>2` = control-specific. The wrapper exposes
   this as the `RGGResult` enum; convenience methods return `BOOL`
   (YES = pressed/changed) and `...Raw` variants return the raw result. See
   `src/RayguiObjC.h` for the exact convention.

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

Pinned versions live in `VERSIONS.md`. Submodules must be initialized at the
pinned tags (plus the cherry-picked fix — see VERSIONS.md):

```sh
git submodule update --init
# if the raygui submodule was reset to the bare tag, re-apply the fix:
(cd vendor/raygui && git am ../../patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch)
```

Build raylib statically, then the demo:

```sh
cd vendor/raylib
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_EXAMPLES=OFF
cmake --build build --config Release
cd ../..
```

macOS:

```sh
make            # see Makefile for the clang command
```

Linux (GNUstep):

```sh
make -f GNUmakefile
```

Full build commands, including framework/library flags, are in AGENTS.md §5 and
in the two makefiles.

## Status

See `TODO.md` for the current progress log and `AGENTS.md` for the full
project brief (design, mapping table, acceptance criteria).
