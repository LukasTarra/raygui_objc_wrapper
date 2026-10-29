#!/bin/sh
# build-deps.sh — cross-build the wasm dependencies into .wasm-deps/ (isolated
# prefix; nothing is installed system-wide) and build raylib for PLATFORM=Web.
#
# Idempotent: safe to re-run. Layout:
#   .wasm-deps/src/libobjc2/   libobjc2 (GNUstep ObjC runtime) source clone
#   .wasm-deps/include,lib/    installed libobjc2 headers + libobjc.a (wasm)
#   vendor/raylib/build-web/   raylib compiled for PLATFORM=Web
#
# Requires: emcc/emcmake (emscripten), cmake, git.
set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"

DEPS="$ROOT/.wasm-deps"
LIBOBJC2_SRC="$DEPS/src/libobjc2"
PATCH="$ROOT/wasm/patches/libobjc2-wasm.patch"

echo "==> libobjc2 (GNUstep ObjC runtime, wasm32-emscripten)"
if [ ! -d "$LIBOBJC2_SRC/.git" ]; then
    mkdir -p "$LIBOBJC2_SRC"
    git clone --depth 1 https://github.com/gnustep/libobjc2.git "$LIBOBJC2_SRC"
fi
cd "$LIBOBJC2_SRC"
if ! git apply --check "$PATCH" 2>/dev/null; then
    if git apply --reverse --check "$PATCH" 2>/dev/null; then
        echo "    patches already applied"
    else
        echo "    applying wasm patches"
        git apply "$PATCH"
    fi
fi
# WASM build: static lib, non-fragile v2 ABI only (OLDABI_COMPAT must be off).
emcmake cmake -B build-wasm \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$DEPS" \
    -DTESTS=OFF
cmake --build build-wasm -j "$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
cmake --install build-wasm
cd "$ROOT"

echo "==> raylib (PLATFORM=Web, OpenGL ES2)"
cd "$ROOT/vendor/raylib"
emcmake cmake -B build-web \
    -DPLATFORM=Web \
    -DBUILD_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-web -j "$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
cd "$ROOT"

echo "==> deps ready:"
echo "    $DEPS/lib/libobjc.a"
echo "    $ROOT/vendor/raylib/build-web/raylib/libraylib.a"
