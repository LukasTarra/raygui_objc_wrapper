#!/bin/sh
# scripts/init-submodules.sh — initialize pinned submodules for a fresh clone.
#
# Run from the repo root after `git clone`:
#
#     sh scripts/init-submodules.sh
#
# What it does:
#   1. git submodule update --init  (fetches vendor/raylib @ 6.0 and
#      vendor/raygui @ 5.0 — both gitlinks point at upstream tags, so this
#      works on any fresh clone)
#   2. Applies the hue-bar fix to vendor/raygui as a working-tree patch
#      (patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch). The patch is
#      the upstream commit 3ea06d4c3d "Fix issue with GuiColorPicker()".
#      It is applied with `git apply` (NOT cherry-picked) so the submodule
#      stays at the exact upstream tag 5.0 — no local-only commits, no
#      unpushable gitlinks.
#
# Idempotent: safe to re-run. If the patch is already applied, step 2 is
# skipped.

set -e

cd "$(dirname "$0")/.."

echo "==> Initializing submodules (raylib @ 6.0, raygui @ 5.0)"
git submodule update --init

echo "==> Verifying pins"
raylib_sha=$(git -C vendor/raylib rev-parse HEAD)
raygui_sha=$(git -C vendor/raygui rev-parse HEAD)
echo "    vendor/raylib @ $raylib_sha (expect dbc56a87da87d973a9c5baa4e7438a9d20121d28)"
echo "    vendor/raygui @ $raygui_sha (expect 020a61bebcbe288b4414de3416e219ef40af847a)"

if [ "$raylib_sha" != "dbc56a87da87d973a9c5baa4e7438a9d20121d28" ]; then
    echo "ERROR: vendor/raylib is not at the pinned tag 6.0" >&2
    exit 1
fi
if [ "$raygui_sha" != "020a61bebcbe288b4414de3416e219ef40af847a" ]; then
    echo "ERROR: vendor/raygui is not at the pinned tag 5.0" >&2
    exit 1
fi

echo "==> Applying hue-bar fix to vendor/raygui (if not already applied)"
if git -C vendor/raygui diff --quiet -- src/raygui.h; then
    git -C vendor/raygui apply --check ../../patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch 2>/dev/null \
        && git -C vendor/raygui apply ../../patches/raygui-5.0-gui-colorpicker-hue-bar-fix.patch \
        && echo "    patch applied" \
        || { echo "ERROR: hue-bar patch does not apply cleanly" >&2; exit 1; }
else
    echo "    patch already applied (working tree dirty), skipping"
fi

echo "==> Done. Next: build raylib, then 'make' (macOS) or 'make -f GNUmakefile' (Linux)."
echo "    cd vendor/raylib && cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF && cmake --build build && cd ../.."
