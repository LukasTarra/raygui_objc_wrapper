# Makefile — macOS build (clang, Cocoa Foundation, no ARC).
#
# Prerequisites:
#   1. sh scripts/init-submodules.sh
#      (initializes vendor/raylib @ 6.0 and vendor/raygui @ 5.0, and applies
#       the hue-bar fix patch to the raygui working tree)
#   2. Build raylib statically:
#      cd vendor/raylib && cmake -B build -DCMAKE_BUILD_TYPE=Release \
#        -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF && cmake --build build
#      cd ../..
#   3. make            # builds examples/demo/demo
#
# raygui is header-only: src/RayguiImplementation.m is the single TU that
# defines RAYGUI_IMPLEMENTATION (AGENTS.md §2.1).

CC      ?= clang
CFLAGS  ?= -x objective-c -fno-objc-arc -std=c11 -Wall -O2
INCLUDES = -Isrc -Ivendor/raygui/src -Ivendor/raylib/src

RAYLIB_A = vendor/raylib/build/raylib/libraylib.a

# raylib 6.0 on macOS (Desktop/GLFW): miniaudio runtime-links CoreAudio, so
# only these frameworks are needed at link time.
FRAMEWORKS = -framework Foundation -framework Cocoa -framework IOKit \
             -framework CoreFoundation -framework OpenGL

SRC = src/RayguiImplementation.m src/RGGControls.m src/RGGContainers.m \
      src/RGGAdvanced.m src/RGGState.m
DEMO = examples/demo/main.m
OUT = examples/demo/demo

.PHONY: all clean run

all: $(OUT)

$(OUT): $(SRC) $(DEMO) $(RAYLIB_A)
	$(CC) $(CFLAGS) $(INCLUDES) $(SRC) $(DEMO) $(RAYLIB_A) $(FRAMEWORKS) -o $(OUT)

run: $(OUT)
	./$(OUT)

clean:
	rm -f $(OUT)
