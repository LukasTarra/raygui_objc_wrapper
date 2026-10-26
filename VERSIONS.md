# VERSIONS.md — Pinned Dependencies

Single source of truth for the pinned upstream versions. Never build against
`master` of either repo: raygui master tracks raylib master, and the pair moves
continuously. Any change here requires re-running the Phase 2 compile proof
(raylib static build + raygui `controls_test_suite`) on both platforms.

## raylib

| Field  | Value                                                                                          |
| ------ | ---------------------------------------------------------------------------------------------- |
| Repo   | https://github.com/raysan5/raylib                                                              |
| Tag    | `6.0`                                                                                          |
| Commit | `dbc56a87da87d973a9c5baa4e7438a9d20121d28` (2026-04-22)                                         |
| Link   | https://github.com/raysan5/raylib/commit/dbc56a87da87d973a9c5baa4e7438a9d20121d28                 |
| Submodule path | `vendor/raylib`                                                                      |

Primary pin: the pairing raygui 5.0 was built and tested against.

Optional alternative: tag `6.2` (`02566453880e06bec97f5b8160fa6fe1e98397ca`).
raylib 6.2 redesigned the file API; adopt 6.2 only if raygui 5.0 compiles clean
against it. Any mismatch fails at compile time, not silently. Not adopted.

## raygui

| Field  | Value                                                                                          |
| ------ | ---------------------------------------------------------------------------------------------- |
| Repo   | https://github.com/raysan5/raygui                                                              |
| Tag    | `5.0`                                                                                          |
| Commit | `020a61bebcbe288b4414de3416e219ef40af847a` (2026-07-20, release "raygui v5.0")                 |
| Link   | https://github.com/raysan5/raygui/commit/020a61bebcbe288b4414de3416e219ef40af847a                 |
| Submodule path | `vendor/raygui`                                                                      |

### Hue-bar fix in `GuiColorPicker` (applied as a working-tree patch)

raygui 5.0 ships a known defect: the hue bar in `GuiColorPicker()` disappears
because the hue-bar update is skipped when the result is already
`RESULT_CHANGED`. As of 2026-10-26 no patched release (5.0.1+) exists —
`v5.0` is still the latest release at https://github.com/raysan5/raygui/releases —
so per AGENTS.md §1 we pin tag `5.0` and apply ONLY the upstream fix:

| Field  | Value                                                                                          |
| ------ | ---------------------------------------------------------------------------------------------- |
| Upstream commit | `3ea06d4c3d1fe32acdbcd364118d55c1f69c8ef1` "Fix issue with `GuiColorPicker()`" (2026-07-21)   |
| Link   | https://github.com/raysan5/raygui/commit/3ea06d4c3d1fe32acdbcd364118d55c1f69c8ef1                 |
| Submodule gitlink | `020a61bebcbe288b4414de3416e219ef40af847a` (the bare upstream tag `5.0` — fetchable by anyone) |
| Diff   | 1 line in `src/raygui.h`: `if (result != RESULT_CHANGED) result = GuiColorBarHue(...)` → `result = GuiColorBarHue(...)` |

**How it is applied:** the submodule gitlink points at the upstream tag (NOT a
local cherry-pick — a local commit would be unpushable and would break fresh
clones). The fix is applied as a **working-tree patch** by
`scripts/init-submodules.sh`:

```sh
sh scripts/init-submodules.sh
```

The patch file is committed at `patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch`.
After init, `vendor/raygui` has a dirty working tree (`M src/raygui.h`) — that
is intentional and expected; do not commit or reset it. The script is
idempotent and verifies both pins before applying.

## Verification record

- 2026-10-26, Linux x86_64 (Debian 13 sandbox, gcc 14.2, cmake 4.4.4/ninja):
  - `vendor/raylib` built statically (`libraylib.a`, 3.5 MB) with
    `PLATFORM=PLATFORM_DESKTOP`, `GRAPHICS=GRAPHICS_API_OPENGL_33`, X11 + miniaudio.
  - raygui `examples/controls_test_suite` compiled and linked against the pinned
    pair with `-Wall`: **0 errors, 0 warnings** from the pinned sources.
- 2026-10-26, Linux x86_64 (Debian 13 sandbox, clang 19.1.7, GNUstep 1.31):
  - Full wrapper (`src/*.m`) + `examples/demo/main.m` compiled with `-Wall`:
    **0 errors, 0 new warnings** (only upstream raygui `GuiFontIconBaking`
    unused-function warning inside the implementation TU).
  - Demo linked into a working ELF; TU rule proven via `nm` (all 61 `Gui*`
    `T` symbols defined exactly once, only in `RayguiImplementation.o`).
  - Headless run: exits cleanly via `IsWindowReady()` guard (no X server in sandbox).
- 2026-10-26, Linux x86_64 (Debian 13 sandbox, clang 19.1.7, GNUstep 1.31):
  - **Makefile fix verified end-to-end**: `make` (GNU make picks `GNUmakefile`,
    which is now identical to `Makefile` and dispatches on `uname -s`) compiles
    all 6 `.m` files to `.o` via the pattern rule (`-x objective-c` applies
    only to sources), then links with `$(CC) $(OBJ) $(LIBS) $(LDFLAGS) -o $(OUT)`
    — **no `-x` at link**, so `libraylib.a` is linked as a static library.
    Demo binary produced and runs (exits cleanly headless). This fixes the
    user-reported macOS failure: `gnustep-config: Command not found` (GNUmakefile
    shadowing) + `libraylib.a` parsed as Obj-C source (`-x` leaking onto the archive).
- 2026-10-26, macOS 27 (Apple M1 Pro, clang, Cocoa Foundation) — verified by user:
  - `make` builds the wrapper + demo clean (Makefile/GNUmakefile dispatch on `uname -s`).
  - `./examples/demo/demo` runs: raylib 6.0 initializes (Metal-backed OpenGL 4.1),
    window opens at 800x450, clean shutdown on close.
- macOS interactive control verification (button/checkbox/slider/textbox): pending user testing.
