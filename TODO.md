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
- [x] Add `vendor/raygui` submodule, pin tag `5.0` (commit `020a61bebcbe288b4414de3416e219ef40af847a`) + cherry-pick ONLY the hue-bar fix commit from master — cherry-picked `3ea06d4c3d1fe32acdbcd364118d55c1f69c8ef1` ("Fix issue with `GuiColorPicker()`"), local SHA `b7d0c0eb00882c51a95d3460b6f0dba1075027f0`; patch also saved at `patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch` for reproducible clones
- [x] Verify exact tag names (`5.0` vs `v5.0`, etc.) against upstream and lock resolved SHAs — tags are unversioned (`5.0`, `6.0`), SHAs locked in `VERSIONS.md`
- [x] Record tags, SHAs, and any cherry-picked fix (with upstream link) in `VERSIONS.md`

## Phase 2 — Prove the pinned pair compiles (AGENTS.md §6.2)

- [x] Build raylib statically (cmake, `BUILD_SHARED_LIBS=OFF`, no examples/games) — `vendor/raylib/build/raylib/libraylib.a` (3.5 MB), PLATFORM_DESKTOP / OpenGL 3.3 / X11 / miniaudio, gcc 14.2, zero errors
- [x] Compile raygui's C example `controls_test_suite` against the pinned pair on the host platform — **compiles and links clean with `-Wall`: 0 errors, 0 warnings from pinned sources** (Linux x86_64)
- [x] If it fails against raylib 6.2, stay on 6.0 — not applicable: pair compiles clean on 6.0, staying on 6.0
- [x] Verify raygui 5.0 result enum names against the pinned `raygui.h` — confirmed: `GuiResult` enum with `RESULT_NONE=0`, `RESULT_PRESSED=1`, `RESULT_CHANGED=2`, `RESULT_TAB_CLOSE=4` (raygui.h:560-565)

## Phase 3 — Single implementation TU (AGENTS.md §6.3)

- [ ] Create `src/RayguiImplementation.m` — the ONLY file defining `RAYGUI_IMPLEMENTATION`
- [ ] Recompile the C example through the ObjC build to prove the TU rule is respected (no duplicate symbols)

## Phase 4 — Wrapper implementation (AGENTS.md §6.4)

- [ ] Write `src/RayguiObjC.h` with the full mapping from AGENTS.md §3.1 (facade `RGGui`, `RGGResult` enum, `RGRectMake` helper)
- [ ] Verify raygui 5.0 result enum/macro names (`RESULT_PRESSED`, `RESULT_CHANGED`) in the pinned `raygui.h`
- [ ] Create `src/RGGControls.h` / `src/RGGControls.m` (button, label, label button, toggle, toggle group, check box, slider, slider bar, progress bar, text box, value box, combo box, dropdown box, spinner)
- [ ] Create `src/RGGContainers.m` (group box, window box, scroll panel, status bar)
- [ ] Create `src/RGGAdvanced.m` (list view, color picker, message box, text input dialog, tab bar)
- [ ] Create `src/RGGState.m` (load style, set font, set icon scale, enable/disable/lock/unlock/set state, icon-text convenience)

## Phase 5 — Demo / acceptance harness (AGENTS.md §6.5)

- [ ] Write `examples/demo/main.m` (label, button toggling a checkbox, slider bound to a float, text box bound to an NSMutableString, style load at startup)
- [ ] Build via `Makefile` (macOS path)
- [ ] Verify demo behavior visually against raygui's own `controls_test_suite`

## Phase 6 — Second platform (AGENTS.md §6.6)

- [ ] Write `GNUmakefile` (Linux / GNUstep path)
- [ ] Build and run the demo under GNUstep on Linux; fix any Cocoa/GNUstep divergences (expected: none beyond flags)

## Phase 7 — Finalize (AGENTS.md §6.7, §7)

- [ ] Finalize `VERSIONS.md` (both repos, tags, SHAs, cherry-pick link)
- [ ] Write `README.md`

## Acceptance criteria checklist (AGENTS.md §7)

- [x] Pinned pair compiles with zero errors and no new warnings on Linux gcc 14.2 (raylib static + controls_test_suite, `-Wall` clean) — macOS clang and GNUstep clang still pending (need respective toolchains)
- [ ] Demo on both platforms: button click returns YES, checkbox toggles, slider moves bound float, text box edits bound NSMutableString, style file loads and restyles controls
- [ ] Exactly one file defines `RAYGUI_IMPLEMENTATION`
- [ ] No AppKit/GUI-toolkit imports anywhere in `src/`; Foundation only
- [ ] No stored `UTF8String` pointers; no per-frame heap allocations beyond autoreleased NSString conversions
- [x] `VERSIONS.md` lists both repos, tags, commit SHAs, and the cherry-picked fix with its upstream link
