# GNUmakefile — Linux / GNUstep build (clang or gcc, GNUstep Foundation, no ARC).
#
# Prerequisites:
#   1. sh scripts/init-submodules.sh
#      (initializes vendor/raylib @ 6.0 and vendor/raygui @ 5.0, and applies
#       the hue-bar fix patch to the raygui working tree)
#   2. Build raylib statically:
#      cd vendor/raylib && cmake -B build -DCMAKE_BUILD_TYPE=Release \
#        -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF && cmake --build build
#      cd ../..
#   3. make -f GNUmakefile        # builds examples/demo/demo
#
# System packages (Debian/Ubuntu): gnustep-devel libx11-dev libxrandr-dev
#   libxinerama-dev libxcursor-dev libxi-dev libxext-dev libgl-dev
#   libasound2-dev libpulse-dev (audio backends for raylib's miniaudio)

CC      ?= clang
GNUSTEP_CONFIG ?= gnustep-config

OBJCFLAGS = $(shell $(GNUSTEP_CONFIG) --objc-flags) -fno-objc-arc -std=c11 -Wall -O2
INCLUDES  = -Isrc -Ivendor/raygui/src -Ivendor/raylib/src
GNUSTEP_LIBS = $(shell $(GNUSTEP_CONFIG) --base-libs)

RAYLIB_A = vendor/raylib/build/raylib/libraylib.a

# raylib 6.0 on Linux (Desktop/GLFW + miniaudio, runtime-linked audio)
XLIBS = -lX11 -lXrandr -lXinerama -lXcursor -lXi -lXext -lGL -lrt -lm -lpthread -ldl

SRC = src/RayguiImplementation.m src/RGGControls.m src/RGGContainers.m \
      src/RGGAdvanced.m src/RGGState.m
DEMO = examples/demo/main.m
OUT = examples/demo/demo

.PHONY: all clean run

all: $(OUT)

$(OUT): $(SRC) $(DEMO) $(RAYLIB_A)
	$(CC) -x objective-c $(OBJCFLAGS) $(INCLUDES) $(SRC) $(DEMO) $(RAYLIB_A) $(XLIBS) $(GNUSTEP_LIBS) -o $(OUT)

run: $(OUT)
	./$(OUT)

clean:
	rm -f $(OUT)
