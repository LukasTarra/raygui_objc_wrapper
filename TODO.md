# TODO.md — RayguiObjC Progress Log

Persistent log of what needs to be done vs. what has already been done.
Update this file as work completes; do not delete completed entries —
check them off so the history of the project stays readable.

Legend: `[ ]` pending · `[~]` in progress · `[x]` done

## Phase 0 — Project scaffolding

- [x] Write `AGENTS.md` (mission, pins, rules, design, layout, acceptance criteria)
- [x] Create `TODO.md` and wire it into `AGENTS.md` as the persistent progress log
- [x] Write `README.md` (usage, frame-loop contract, result-value semantics)
- [x] Write `VERSIONS.md` — single source of truth for pinned tags/SHAs (filled in during Phase 1)

## Phase 1 — Pin dependencies (AGENTS.md §6.1)

- [x] Check github.com/raysan5/raygui/releases for a patched release (5.0.1+) containing the `GuiColorPicker` hue-bar fix; pin it if it exists — **no patched release exists (v5.0 still latest as of 2026-10-26), pinning 5.0 + cherry-pick**
- [x] Add `vendor/raylib` submodule, pin tag `6.0` (fallback plan: try `6.2` only after 6.0 works) — pinned `dbc56a87da87d973a9c5baa4e7438a9d20121d28`
- [x] Add `vendor/raygui` submodule, pin tag `5.0` (commit `020a61bebcbe288b4414de3416e219ef40af847a`) + apply ONLY the hue-bar fix from master — upstream `3ea06d4c3d1fe32acdbcd364118d55c1f69c8ef1` ("Fix issue with `GuiColorPicker()`"), applied as a **working-tree patch** (`patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch`) via `scripts/init-submodules.sh` so the gitlink stays at the upstream tag (a local cherry-pick commit would be unpushable and break fresh clones — found and fixed after user hit missing-CMakeLists error)
- [x] Verify exact tag names (`5.0` vs `v5.0`, etc.) against upstream and lock resolved SHAs — tags are unversioned (`5.0`, `6.0`), SHAs locked in `VERSIONS.md`
- [x] Record tags, SHAs, and any cherry-picked fix (with upstream link) in `VERSIONS.md`

## Phase 2 — Prove the pinned pair compiles (AGENTS.md §6.2)

- [x] Build raylib statically (cmake, `BUILD_SHARED_LIBS=OFF`, no examples/games) — `vendor/raylib/build/raylib/libraylib.a` (3.5 MB), PLATFORM_DESKTOP / OpenGL 3.3 / X11 / miniaudio, gcc 14.2, zero errors
- [x] Compile raygui's C example `controls_test_suite` against the pinned pair on the host platform — **compiles and links clean with `-Wall`: 0 errors, 0 warnings from pinned sources** (Linux x86_64)
- [x] If it fails against raylib 6.2, stay on 6.0 — not applicable: pair compiles clean on 6.0, staying on 6.0
- [x] Verify raygui 5.0 result enum names against the pinned `raygui.h` — confirmed: `GuiResult` enum with `RESULT_NONE=0`, `RESULT_PRESSED=1`, `RESULT_CHANGED=2`, `RESULT_TAB_CLOSE=4` (raygui.h:560-565)

## Phase 3 — Single implementation TU (AGENTS.md §6.3)

- [x] Create `src/RayguiImplementation.m` — the ONLY file defining `RAYGUI_IMPLEMENTATION`
- [x] Recompile the C example through the ObjC build to prove the TU rule is respected (no duplicate symbols) — verified via `nm`: `GuiButton` has exactly 1 `T` symbol across all 6 .o files; all 61 `Gui*` `T` symbols live only in `RayguiImplementation.o`
- [x] Base `@implementation RGGui` lives in `RayguiImplementation.m` (GNUstep runtime requires the class definition in exactly one TU when methods are split across categories)

## Phase 4 — Wrapper implementation (AGENTS.md §6.4)

- [x] Write `src/RayguiObjC.h` with the full mapping from AGENTS.md §3.1 (facade `RGGui`, `RGGResult` enum, `RGRectMake` helper) — 90 class methods across 4 categories; every control has a BOOL convenience + `...Raw` variant (uniform mechanism)
- [x] Verify raygui 5.0 result enum/macro names (`RESULT_PRESSED`, `RESULT_CHANGED`) in the pinned `raygui.h` — done in Phase 2, re-confirmed: `GuiResult { RESULT_NONE=0, RESULT_PRESSED=1, RESULT_CHANGED=2, RESULT_TAB_CLOSE=4 }`
- [x] Create `src/RGGControls.m` — button, label, label button, toggle, toggle group, toggle slider, check box, slider, slider bar, progress bar, text box, value box, value box float, combo box, dropdown box, spinner, dummy rec, grid (18 controls)
- [x] Create `src/RGGContainers.m` — group box, window box, panel, line, scroll panel, status bar (6 controls)
- [x] Create `src/RGGAdvanced.m` — list view, color picker, color panel, color bar alpha/hue, color picker/panel HSV, message box, text input dialog, tab bar (10 controls)
- [x] Create `src/RGGState.m` — load style (file + default), set font, set icon scale, enable/disable/lock/unlock/isLocked, set alpha, set/get state, set/get style, tooltips, icon-text convenience, text width
- [x] All 35 raygui control functions wrapped (raygui 5.0 ships 39 `int Gui*` entry points; `GuiGetState`/`GuiGetStyle`/`GuiGetTextWidth` exposed via State category, `GuiListViewEx`/`GuiTabBarEx` used internally by the `;`-joined convenience wrappers)
- [x] Sandbox verification (Linux GNUstep, clang 19.1.7): all 5 wrapper .m files + demo main.m compile clean with `-Wall`; demo links into a working ELF; headless run exits cleanly via `IsWindowReady()` guard

## Phase 5 — Demo / acceptance harness (AGENTS.md §6.5)

- [x] Write `examples/demo/main.m` (label, button toggling a checkbox, slider bound to a float, text box bound to an NSMutableString, style load at startup via argv[1]) — pulled forward from Phase 5 so the macOS test path is runnable now
- [x] Add `Makefile` (macOS: clang, Cocoa Foundation, `-framework Foundation -framework Cocoa -framework IOKit -framework CoreFoundation -framework OpenGL`)
- [x] Add `GNUmakefile` (Linux/GNUstep: `gnustep-config --objc-flags/--base-libs`, X11/GL link line)
- [x] Sandbox build proof: demo compiles + links under GNUstep clang 19 (headless — `IsWindowReady()` guard prevents segfault without DISPLAY)
- [x] Fix macOS `make` failure: (a) `GNUmakefile` shadowed `Makefile` on macOS (GNU make prefers GNUmakefile) → both files now identical, each dispatches on `uname -s`; (b) `-x objective-c` on the old single compile+link command leaked onto `libraylib.a` (clang parsed the archive as source → `!<arch>`/UTF-8 errors) → compile (.m→.o via pattern rule) and link are now separate steps, link has no `-x`. Added `LDFLAGS ?=` for portability. Verified in sandbox: `make` (picks GNUmakefile) compiles all 6 .m files, links demo with `libraylib.a` as a library, binary runs (exits cleanly headless)
- [x] macOS build verified — user built with `make` on macOS 27 (Apple M1 Pro, clang) and ran `./examples/demo/demo`: raylib 6.0 initialized (Metal-backed OpenGL 4.1), window opened 800x450, clean shutdown
- [ ] Verify demo behavior visually against raygui's own `controls_test_suite` — optional cross-check; demo itself runs on macOS

## Phase 6 — Second platform (AGENTS.md §6.6)

- [x] Write `GNUmakefile` (Linux / GNUstep path)
- [x] Build and run the demo under GNUstep on Linux; fix any Cocoa/GNUstep divergences (expected: none beyond flags) — build verified in sandbox (clang 19 + GNUstep 1.31): all sources compile clean, demo links and runs (exits cleanly headless)
- [x] Build and run the demo on macOS (clang, Cocoa Foundation) — verified by user on macOS 27 / M1 Pro: `make` builds, `./examples/demo/demo` runs, raylib 6.0 initializes (Metal/OpenGL 4.1), clean shutdown. Both platforms now proven end-to-end.

## Phase 7 — Finalize (AGENTS.md §6.7, §7)

- [ ] Finalize `VERSIONS.md` (both repos, tags, SHAs, cherry-pick link)
- [ ] Write `README.md`

## Editor tooling

- [x] Add `.ccls` for ccls (macOS clang flags from Makefile; global `-x objective-c` so `RayguiObjC.h` parses as ObjC; `%objective-c%` section adds `-fno-objc-arc -std=c11`) — verified with `ccls --index`: all 7 project files + `raygui.h`/`raylib.h` index with zero errors; `.ccls-cache/` gitignored

## Acceptance criteria checklist (AGENTS.md §7)

- [x] Pinned pair compiles with zero errors and no new warnings on Linux gcc 14.2 (raylib static + controls_test_suite, `-Wall` clean)
- [x] Full wrapper + demo compiles with zero errors and zero new warnings on Linux GNUstep clang 19.1.7 (`-Wall` clean; only upstream raygui `GuiFontIconBaking` unused-function warning in the implementation TU)
- [x] macOS clang build — verified by user on macOS 27 / M1 Pro: `make` builds clean, demo runs, raylib 6.0 initializes, clean shutdown
- [~] Demo on both platforms: button click returns YES, checkbox toggles, slider moves bound float, text box edits bound NSMutableString, style file loads and restyles controls — demo runs on both macOS (verified) and Linux (headless-verified, visual run pending on a Linux+X11 host); interactive control behavior not yet systematically tested
- [x] Exactly one file defines `RAYGUI_IMPLEMENTATION` (verified: `grep -c` = 1, only `src/RayguiImplementation.m`; `nm` confirms no duplicate `Gui*` symbols)
- [x] No AppKit/GUI-toolkit imports anywhere in `src/`; Foundation only (verified: only `#import <Foundation/Foundation.h>` and `#import "RayguiObjC.h"`)
- [x] No stored `UTF8String` pointers (verified: no static/global assignments of `UTF8String` results); no per-frame heap allocations beyond autoreleased NSString conversions (only `RGGJoinItems` and `stringWithUTF8String:` produce autoreleased objects)
- [x] `VERSIONS.md` lists both repos, tags, commit SHAs, and the cherry-picked fix with its upstream link
