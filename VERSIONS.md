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

### Cherry-picked fix (hue bar in `GuiColorPicker`)

raygui 5.0 ships a known defect: the hue bar in `GuiColorPicker()` disappears
because the hue-bar update is skipped when the result is already
`RESULT_CHANGED`. As of 2026-10-26 no patched release (5.0.1+) exists —
`v5.0` is still the latest release at https://github.com/raysan5/raygui/releases —
so per AGENTS.md §1 we pin tag `5.0` and cherry-pick ONLY the upstream fix:

| Field  | Value                                                                                          |
| ------ | ---------------------------------------------------------------------------------------------- |
| Upstream commit | `3ea06d4c3d1fe32acdbcd364118d55c1f69c8ef1` "Fix issue with `GuiColorPicker()`" (2026-07-21)   |
| Link   | https://github.com/raysan5/raygui/commit/3ea06d4c3d1fe32acdbcd364118d55c1f69c8ef1                 |
| Local cherry-pick SHA (in `vendor/raygui`) | `b7d0c0eb00882c51a95d3460b6f0dba1075027f0`                          |
| Diff   | 1 line in `src/raygui.h`: `if (result != RESULT_CHANGED) result = GuiColorBarHue(...)` → `result = GuiColorBarHue(...)` |

The cherry-pick lives only in our submodule checkout (we cannot push to
raysan5/raygui). For reproducible fresh clones, the patch is also committed at
`patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch`; apply it after
`git submodule update --init` if the submodule ever resets to the bare tag:

```sh
cd vendor/raygui && git am ../../patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch
```

## Verification record

- 2026-10-26, Linux x86_64 (Debian 13 sandbox, gcc 14.2, cmake 4.4.4/ninja):
  - `vendor/raylib` built statically (`libraylib.a`, 3.5 MB) with
    `PLATFORM=PLATFORM_DESKTOP`, `GRAPHICS=GRAPHICS_API_OPENGL_33`, X11 + miniaudio.
  - raygui `examples/controls_test_suite` compiled and linked against the pinned
    pair with `-Wall`: **0 errors, 0 warnings** from the pinned sources.
- macOS clang build: pending (Phase 6/7 — requires an Apple toolchain host).
