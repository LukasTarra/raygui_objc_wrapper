# RayguiObjC — Agent Brief: Objective-C Wrapper for raygui 5.0

## 0. Mission

Build `RayguiObjC`, a thin Objective-C wrapper around the raygui 5.0 control API. raylib is NOT wrapped: it is called directly from Objective-C, which is a strict superset of C. Only the \~57 raygui control functions are wrapped. The wrapper must compile and run identically on:

- macOS (Cocoa Foundation, clang)
- Linux (GNUstep Foundation, clang)

The wrapper must depend on Foundation only (NSString, NSObject). Do not use AppKit types (NSRect, NSColor, NSView), so the same source links under both Cocoa and GNUstep without conditional includes.

## 1. Pinned versions (mandatory)

Pin by exact git tag in `raysan5/raygui` and `raysan5/raylib`. Record the tag and the resolved commit SHA in `VERSIONS.md` at the repo root. Never build against `master` of either repo: raygui master tracks raylib master, and the pair moves continuously.


| Component         | Pin                                               | Notes                                                                                                                                                                        |
| ----------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| raygui            | tag `5.0` (commit `020a61b`, released 2026-07-20) | The entire library is `src/raygui.h`. raygui 5.0 was developed against raylib 6.x.                                                                                           |
| raylib            | tag `6.0` (released 2026)                         | Primary pin; the pairing raygui 5.0 was built and tested against.                                                                                                            |
| raylib (optional) | tag `6.2` (released 2026-10-15)                   | Try after the 6.0 build works. raylib 6.2 redesigned the file API; adopt 6.2 only if raygui 5.0 compiles clean against it. Any mismatch fails at compile time, not silently. |


Known defect: raygui 5.0 ships a `GuiColorPicker()` bug (hue bar disappears), already fixed on the raygui master branch. Before starting, check whether a patched release (5.0.1 or later) exists at github.com/raysan5/raygui/releases. If yes, pin that release instead. If no, pin tag `5.0` and cherry-pick ONLY the hue-bar fix commit from master, recording the cherry-picked SHA and a link to the fix commit in `VERSIONS.md`.

At implementation start, verify the exact tag names against the upstream repos (tags may be published as `5.0`, `v5.0`, or similar) and lock the resolved SHAs. Treat `VERSIONS.md` as the single source of truth for versions.

## 2. Non-negotiable integration rules

1. Single-translation-unit rule: `#define RAYGUI_IMPLEMENTATION` goes in exactly one `.m` file (create `src/RayguiImplementation.m` for this purpose and nothing else). Defining it in two files produces duplicate-symbol linker errors.
2. Include order matters: `#include "raylib.h"` must come before `#include "raygui.h"`.
3. raygui 5.0 changed every control function to return a result value: `1` = pressed, `2` = changed, values `>2` are control-specific/custom. Verify the exact enum or macro names in the pinned `raygui.h` (expected form: `RESULT_PRESSED`, `RESULT_CHANGED`) and expose them through a wrapper enum. Do not wrap against raygui 3.x/4.x signatures; most online tutorials are outdated.
4. Immediate mode discipline: every wrapped control must be called once per frame between `BeginDrawing()` and `EndDrawing()`. The wrapper holds no per-control state. Never call controls outside the draw frame.
5. `NSString` bridging: convert with `UTF8String` per call. The returned C pointer is only valid for the duration of the call — never store it. Reuse a per-call stack buffer for controls raygui edits in place.
6. Memory management: manual retain/release (no ARC) so the same code compiles under GNUstep. If ARC is desired on macOS later, it must stay opt-in.

## 3. Wrapper design

One facade class `RGGui` (class methods, no instances needed) plus categories per control group. Use the `RG` prefix to avoid collisions with NS/GNUstep classes. raylib structs (`Rectangle`, `Color`, `Vector2`, `Font`) pass through unwrapped at the boundary — that is the entire point of this approach.

### 3.1 Method mapping (core set)

Wrap at minimum:


| raygui 5.0 function                | Wrapper signature (class method on `RGGui`)                                                                                                                        |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `GuiButton`                        | `+ (BOOL)button:(Rectangle)bounds text:(NSString *)text` — returns YES only on the pressed result                                                                  |
| `GuiLabel`                         | `+ (void)label:(Rectangle)bounds text:(NSString *)text`                                                                                                            |
| `GuiLabelButton`                   | `+ (BOOL)labelButton:(Rectangle)bounds text:(NSString *)text`                                                                                                      |
| `GuiToggle` / `GuiToggleGroup`     | `+ (BOOL)toggle:(Rectangle)bounds text:(NSString *)text active:(BOOL *)active`                                                                                     |
| `GuiCheckBox`                      | `+ (BOOL)checkBox:(Rectangle)bounds text:(NSString *)text checked:(BOOL *)checked` — returns YES when the value changed                                            |
| `GuiSlider` / `GuiSliderBar`       | `+ (BOOL)slider:(Rectangle)bounds text:(NSString *)text value:(float *)value minValue:(float)min maxValue:(float)max`                                              |
| `GuiProgressBar`                   | `+ (void)progressBar:(Rectangle)bounds value:(float)value minValue:(float)min maxValue:(float)max`                                                                 |
| `GuiTextBox`                       | `+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength` — copy NSString into a fixed C buffer, call, write edits back            |
| `GuiValueBox` / `GuiValueBoxFloat` | `+ (BOOL)valueBox:(Rectangle)bounds value:(NSInteger *)value` etc.                                                                                                 |
| `GuiComboBox` / `GuiDropdownBox`   | `+ (BOOL)comboBox:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected` — join items with `;` per raygui convention                       |
| `GuiSpinner`                       | `+ (BOOL)spinner:(Rectangle)bounds value:(int *)value minValue:(int)min maxValue:(int)max`                                                                         |
| `GuiGroupBox` / `GuiWindowBox`     | `+ (BOOL)windowBox:(Rectangle)bounds title:(NSString *)title` — returns YES on close                                                                               |
| `GuiStatusBar`                     | `+ (void)statusBar:(Rectangle)bounds text:(NSString *)text`                                                                                                        |
| `GuiScrollPanel`                   | `+ (Rectangle)scrollPanel:(Rectangle)bounds content:(Rectangle)content scroll:(Vector2 *)scroll`                                                                   |
| `GuiListView`                      | `+ (BOOL)listView:(Rectangle)bounds items:(NSArray<NSString *> *)items selected:(int *)selected scrollIndex:(int *)scroll`                                         |
| `GuiColorPicker`                   | `+ (BOOL)colorPicker:(Rectangle)bounds color:(Color *)color`                                                                                                       |
| `GuiMessageBox`                    | `+ (int)messageBox:(Rectangle)bounds title:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttons`                                   |
| `GuiTextInputBox`                  | `+ (int)textInputDialog:(Rectangle)bounds title:(NSString *)title message:(NSString *)message buttons:(NSArray<NSString *> *)buttons text:(NSMutableString *)text` |
| `GuiTabBar`                        | `+ (int)tabBar:(Rectangle)bounds items:(NSArray<NSString *> *)items active:(int)active`                                                                            |


Also wrap the state API: `GuiLoadStyle` (`+ (BOOL)loadStyleAtPath:(NSString *)path`), `GuiSetFont`, `GuiSetIconScale`, `GuiEnable`/`GuiDisable`/`GuiLock`/`GuiUnlock`/`GuiSetState`, and the icon text helper (icon-prefixed strings work as plain NSString, e.g. `@"#1#OK"`; expose any `GuiIconText`-equivalent as a convenience).

General signature conventions:

- Controls that report the raygui result: return `BOOL` pressed/changed via convenience, and also expose the raw result through a `RGGResult` typedef or a `...Raw` variant. Pick one mechanism and apply it uniformly; document it in the header.
- In/out scalars are passed by pointer (C convention) — do not invent NSNumber round-trips in the per-frame path.
- Every method takes `Rectangle bounds` first. Provide one C helper `RGRectMake(float x, float y, float w, float h)` mirroring `NSRectMake` for readability.

### 3.2 Skeletons

`src/RayguiImplementation.m` — the single implementation TU:

```objc
// The ONLY file that defines RAYGUI_IMPLEMENTATION.
#include "raylib.h"
#define RAYGUI_IMPLEMENTATION
#include "raygui.h"
```

`src/RayguiObjC.h` — public header:

```objc
#import <Foundation/Foundation.h>
#include "raylib.h"   // Rectangle, Color, Vector2 pass through unwrapped

typedef NS_ENUM(int, RGGResult) {
    RGGResultIdle    = 0,
    RGGResultPressed = 1,
    RGGResultChanged = 2
};

static inline Rectangle RGRectMake(float x, float y, float w, float h) {
    Rectangle r = { x, y, w, h };
    return r;
}

@interface RGGui : NSObject
// Controls group
+ (BOOL)button:(Rectangle)bounds text:(NSString *)text;
+ (BOOL)checkBox:(Rectangle)bounds text:(NSString *)text checked:(BOOL *)checked;
+ (BOOL)slider:(Rectangle)bounds text:(NSString *)text
         value:(float *)value minValue:(float)min maxValue:(float)max;
+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength;
// ... remaining controls per the mapping table
// State group
+ (BOOL)loadStyleAtPath:(NSString *)path;
+ (void)enable;
+ (void)disable;
+ (void)lock;
+ (void)unlock;
@end
```

`src/RGGControls.m` — typical implementation pattern:

```objc
#import "RayguiObjC.h"
#include "raygui.h"

@implementation RGGui

+ (BOOL)button:(Rectangle)bounds text:(NSString *)text {
    int result = GuiButton(bounds, [text UTF8String]);
    return (result == RGGResultPressed);
}

+ (BOOL)textBox:(Rectangle)bounds text:(NSMutableString *)text maxLength:(int)maxLength {
    char buf[256];  // maxLength must be <= 255; assert or clamp
    snprintf(buf, sizeof(buf), "%s", [text UTF8String]);
    int result = GuiTextBox(bounds, buf, maxLength);
    [text setString:[NSString stringWithUTF8String:buf]];
    return (result == RGGResultChanged);
}

@end
```

### 3.3 Example app (acceptance harness)

`examples/demo/main.m` — open a window, then per frame: label, button that toggles a checkbox, slider bound to a float, text box bound to an NSMutableString, and a style file load at startup. This is the acceptance test; port it from raygui's own `examples/controls_test_suite` structure so behavior can be compared visually.

## 4. Project layout

```
raygui-objc/
  VERSIONS.md
  vendor/raylib/        (submodule, tag 6.0, built statically)
  vendor/raygui/        (submodule, tag 5.0 [+ hue-bar fix commit])
  src/RayguiObjC.h
  src/RGGControls.h
  src/RGGControls.m
  src/RGGContainers.m   (group box, window box, scroll panel, status bar)
  src/RGGAdvanced.m    (list view, color picker, message box, text input, tab bar)
  src/RGGState.m        (styles, font, state, icons)
  src/RayguiImplementation.m
  examples/demo/main.m
  Makefile              (macOS path)
  GNUmakefile           (Linux / GNUstep path)
  README.md
```

## 5. Build instructions

raylib (static, both platforms):

```sh
cd vendor/raylib
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_EXAMPLES=OFF -DBUILD_GAMES=OFF
cmake --build build --config Release
```

macOS (clang, no ARC):

```sh
clang -x objective-c -fno-objc-arc -std=c11 \
  src/*.m examples/demo/main.m \
  -Isrc -Ivendor/raygui/src -Ivendor/raylib/src \
  vendor/raylib/build/libraylib.a \
  -framework Foundation -framework IOKit -framework Cocoa -framework OpenGL \
  -o demo
```

(Adjust the framework list to what the pinned raylib actually links on macOS; on Apple Silicon use Metal instead of OpenGL if the raylib build selected it — check `vendor/raylib/build` link flags.)

Linux (GNUstep):

```sh
# Foundation flags via gnustep-config
CFLAGS="$(gnustep-config --objc-flags) -Isrc -Ivendor/raygui/src -Ivendor/raylib/src"
clang -x objective-c -fno-objc-arc -std=c11 $CFLAGS \
  src/*.m examples/demo/main.m \
  vendor/raylib/build/libraylib.a \
  -lX11 -lGL -lpthread -lm -ldl \
  -o demo
```

Provide both a plain `Makefile` and a GNUstep `GNUmakefile` that build the same sources; keep flags in one place per file. Build the demo on both platforms before declaring done.

## 6. Implementation order

1. Clone/pin submodules at the exact tags; write `VERSIONS.md` (tag, SHA, cherry-picked fix if any).
2. Build raylib statically on the host platform; compile raygui's C example `controls_test_suite` to prove the pinned pair compiles together. If it fails against raylib 6.2, stay on 6.0.
3. Add `RayguiImplementation.m`; compile the C example again through the ObjC build to prove the TU rule is respected.
4. Write `RayguiObjC.h` with the full mapping; implement `RGGControls`, `RGGContainers`, `RGGAdvanced`, `RGGState` in that order.
5. Write `examples/demo/main.m`; verify visually against raygui's own examples.
6. Port the build to the second platform; fix GNUstep/Cocoa divergences (expected to be none beyond flags).
7. Write `README.md` (usage, frame-loop contract, result-value semantics) and finalize `VERSIONS.md`.

## 7. Acceptance criteria

- The pinned pair (raygui 5.0 + raylib 6.0, plus only the hue-bar fix if needed) compiles with zero errors and no new warnings on macOS clang and Linux GNUstep clang.
- Demo runs on both platforms: button click returns YES, checkbox toggles, slider moves the bound float, text box edits the bound NSMutableString, style file loads and restyles all controls.
- Exactly one file defines `RAYGUI_IMPLEMENTATION`.
- No AppKit/GUI-toolkit imports anywhere in `src/`; Foundation only.
- No stored `UTF8String` pointers; no per-frame heap allocations in the wrapper beyond NSString conversions covered by the autorelease pool.
- `VERSIONS.md` lists both repos, tags, commit SHAs, and the cherry-picked fix with its upstream link.

## 8. Known pitfalls

- Version skew: raygui master tracks raylib master; a mismatched pair fails at compile time. Only the pinned pair is supported.
- Never mix the 3.x/4.x API (void returns on most controls) with 5.0 signatures.
- Do not call controls outside `BeginDrawing`/`EndDrawing`; raygui reads raylib input state and draws via raylib primitives, both invalid outside the frame.
- `GuiTextBox` edits the C buffer in place; always clamp `maxLength` below the stack buffer size and use `snprintf`, never `sprintf`.
- Icon text in labels (`@"#1#OK"` style) must pass through unmodified — do not strip or re-encode.
- OS X 10.9 Mavericks is out of scope for this pinned pair: raylib 6.x requires a current toolchain. If a Mavericks target is later required, that is a separate effort with older pins (raylib 5.x, OpenGL 2.1/3.3 backend) and the same wrapper API.
